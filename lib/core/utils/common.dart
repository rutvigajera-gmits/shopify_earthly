import 'dart:io';

import 'package:demo_earthly/component/cached_image_widget.dart';
import 'package:demo_earthly/core/theme/app_colors.dart';
import 'package:demo_earthly/store/appstore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as custom_tabs;
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:path_provider/path_provider.dart';

Future<File> getCameraImage({bool isCamera = true}) async {
  final pickedImage = await ImagePicker()
      .pickImage(source: isCamera ? ImageSource.camera : ImageSource.gallery);
  return File(pickedImage!.path);
}

Future<List<File>> getMultipleImageSource({bool isCamera = true}) async {
  final pickedImage = await ImagePicker().pickMultiImage();
  return pickedImage.map((e) => File(e.path)).toList();
}


Widget mobileNumberInfoWidget(BuildContext context) {
  return RichTextWidget(
    list: [
      TextSpan(
        text: 'Add your country code',
        style: secondaryTextStyle(),
      ),
      TextSpan(text: ' "260-", "236-" ', style: boldTextStyle(size: 12)),
      TextSpan(
        text: ' (Help)',
        style: boldTextStyle(size: 12, color: context.primaryColor),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            launchUrlCustomTab("https://countrycode.org/");
          },
      ),
    ],
  );
}

void launchUrlCustomTab(String? url) {
  if (url.validate().isNotEmpty) {
    custom_tabs.launchUrl(
      Uri.parse(url!),
      customTabsOptions: custom_tabs.CustomTabsOptions(
        showTitle: true,
        colorSchemes: custom_tabs.CustomTabsColorSchemes.defaults(
          toolbarColor: AppColors.primary,
        ),
      ),
      safariVCOptions: const custom_tabs.SafariViewControllerOptions(
        preferredBarTintColor: AppColors.primary,
        preferredControlTintColor: Colors.white,
        barCollapsingEnabled: true,
        entersReaderIfAvailable: true,
        dismissButtonStyle: custom_tabs.SafariViewControllerDismissButtonStyle.close,
      ),
    );
  }
}

Future<List<File>> pickFiles({
  FileType type = FileType.any,
  List<String> allowedExtensions = const [],
  int maxFileSizeMB = 5,
  bool allowMultiple = false,
}) async {
  final List<File> _filePath = [];
  try {
    final FilePickerResult? filePickerResult = await FilePicker.platform.pickFiles(
      type: type,
      allowMultiple: allowMultiple,
      withData: Platform.isAndroid ? false : true,
      allowedExtensions: allowedExtensions,
      onFileLoading: (FilePickerStatus status) => print(status),
    );
    if (filePickerResult != null) {
      if (Platform.isAndroid) {
        // For Android, check file size and use the PlatformFile directly
        for (final PlatformFile file in filePickerResult.files) {
          if (file.size <= maxFileSizeMB * 1024 * 1024) {
            _filePath.add(File(file.path!));
          } else {
            // File size exceeds the limit
            toast('File size should be less than $maxFileSizeMB MB');
          }
        }
      } else {
        final Directory cacheDir = await getTemporaryDirectory();
        for (final PlatformFile file in filePickerResult.files) {
          if (file.bytes != null && file.size <= maxFileSizeMB * 1024 * 1024) {
            final String filePath = '${cacheDir.path}/${file.name}';
            final File cacheFile = File(filePath);
            await cacheFile.writeAsBytes(file.bytes!.toList());
            _filePath.add(cacheFile);
          } else {
            // File size exceeds the limit
            toast('File size should be less than $maxFileSizeMB MB');
          }
        }
      }
    }
  } on PlatformException catch (e) {
    print('Unsupported operation$e');
  } catch (e) {
    print(e);
  }
  return _filePath;
}

//region Multi Language Component
class MultiLanguageWidget extends StatelessWidget {
  final Function(LanguageDataModel languageDetails) onTap;

  const MultiLanguageWidget({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (context) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(color: context.scaffoldBackgroundColor),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(
                languageList().length,
                (index) {
                  LanguageDataModel languageData = languageList()[index];
                  return ElevatedButton(
                    onPressed: () {
                      onTap(languageData);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appStore.selectedLanguage.languageCode ==
                              languageData.languageCode
                          ? context.primaryColor
                          : context.scaffoldBackgroundColor,
                      elevation: 0,
                      side: BorderSide(width: 1, color: context.iconColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CachedImageWidget(
                            url: languageData.flag.validate(), height: 16),
                        4.width,
                        Text(languageData.name.validate().toUpperCase(),
                            style: secondaryTextStyle(
                                color: appStore.selectedLanguage.languageCode ==
                                        languageData.languageCode
                                    ? white
                                    : textSecondaryColorGlobal))
                      ],
                    ),
                  ).paddingOnly(
                      right: 8,
                      left: languageList().first.languageCode ==
                              languageData.languageCode
                          ? 16
                          : 0);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
//endregion

List<LanguageDataModel> languageList() {
  return [
    LanguageDataModel(
      id: 1,
      name: 'English',
      languageCode: 'en',
      fullLanguageCode: 'en-US',
      flag: 'assets/flag/ic_us.png',
    ),
    LanguageDataModel(
      id: 2,
      name: 'Hindi',
      languageCode: 'hi',
      fullLanguageCode: 'hi-IN',
      flag: 'assets/flag/ic_india.png',
    ),
    LanguageDataModel(
      id: 3,
      name: 'Arabic',
      languageCode: 'ar',
      fullLanguageCode: 'ar-AR',
      flag: 'assets/flag/ic_ar.png',
    ),
    LanguageDataModel(
      id: 4,
      name: 'French',
      languageCode: 'fr',
      fullLanguageCode: 'fr-FR',
      flag: 'assets/flag/ic_fr.png',
    ),
    LanguageDataModel(
      id: 5,
      name: 'German',
      languageCode: 'de',
      fullLanguageCode: 'de-DE',
      flag: 'assets/flag/ic_de.png',
    ),
  ];
}