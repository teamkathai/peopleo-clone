Place an open-source face embedding model here:

  mobilefacenet.tflite   (112x112 input, 192-d or 128-d embedding)

Recommended: MobileFaceNet TFLite (MIT/Apache builds are widely available).
The app loads this file in lib/services/face/face_recognizer.dart.
If the file is missing, the app still runs; recognition returns a clear
"model not loaded" state and only ML Kit detection + liveness run.
