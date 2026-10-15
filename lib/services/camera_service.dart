import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/permission_helper.dart';

class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  bool _isFlashOn = false;

  CameraController? get controller => _controller;
  List<CameraDescription> get cameras => _cameras;
  int get selectedCameraIndex => _selectedCameraIndex;
  bool get isInitialized => _isInitialized && _controller != null && _controller!.value.isInitialized;
  bool get isTakingPicture => _isTakingPicture;
  bool get isFlashOn => _isFlashOn;
  bool get hasMultipleCameras => _cameras.length > 1;
  bool get isFrontCamera =>
      _cameras.isNotEmpty &&
      _selectedCameraIndex < _cameras.length &&
      _cameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front;

  Future<bool> initializeCamera({int? cameraIndex}) async {
    try {
      final hasPermission = await PermissionHelper.requestCameraPermission();
      if (!hasPermission) {
        print("Camera permission not granted");
        return false;
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        print("No cameras available on this device");
        return false;
      }

      // If specific index requested, use it; otherwise prefer front camera on laptops/desktops
      // or back camera on mobile phones
      if (cameraIndex != null && cameraIndex < _cameras.length) {
        _selectedCameraIndex = cameraIndex;
      } else {
        // Find best default camera:
        // On laptops (web/desktop), front camera is typical.
        // On mobile, back camera is typical for outward environmental view.
        int foundIndex = -1;
        if (kIsWeb) {
          // On laptops/browsers, select front camera or first available
          foundIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
        } else {
          foundIndex = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
        }

        if (foundIndex != -1) {
          _selectedCameraIndex = foundIndex;
        } else {
          _selectedCameraIndex = 0;
        }
      }

      final selectedCamera = _cameras[_selectedCameraIndex];

      ImageFormatGroup? formatGroup;
      if (!kIsWeb) {
        formatGroup = defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.jpeg
            : ImageFormatGroup.bgra8888;
      }

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: formatGroup,
      );

      await _controller!.initialize();
      _isInitialized = true;
      notifyListeners();
      return true;
    } catch (e) {
      print("Camera initialization error: $e");
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  /// Switch between Front (Laptop webcam / Selfie) and Back (Rear) cameras
  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    notifyListeners();

    await initializeCamera(cameraIndex: _selectedCameraIndex);
  }

  Future<XFile?> takePicture() async {
    if (!isInitialized || _isTakingPicture) return null;

    try {
      _isTakingPicture = true;
      notifyListeners();

      final XFile photo = await _controller!.takePicture();
      _isTakingPicture = false;
      notifyListeners();
      return photo;
    } catch (e) {
      print("Error taking picture: $e");
      _isTakingPicture = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> toggleFlash() async {
    if (!isInitialized) return;
    try {
      if (_isFlashOn) {
        await _controller!.setFlashMode(FlashMode.off);
        _isFlashOn = false;
      } else {
        await _controller!.setFlashMode(FlashMode.torch);
        _isFlashOn = true;
      }
      notifyListeners();
    } catch (e) {
      print("Error toggling flash: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
