import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

/// Ensures ImagePickerPlatform is bound to ImagePickerPlugin on web,
/// preventing fallback to MethodChannelImagePicker.
void ensureWebPluginRegistered() {
  if (ImagePickerPlatform.instance is! ImagePickerPlugin) {
    ImagePickerPlatform.instance = ImagePickerPlugin();
  }
}
