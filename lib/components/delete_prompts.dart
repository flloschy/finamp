import 'package:finamp/components/confirmation_prompt_dialog.dart';
import 'package:finamp/components/global_snackbar.dart';
import 'package:finamp/models/finamp_models.dart';
import 'package:finamp/screens/album_screen.dart';
import 'package:finamp/services/downloads_service.dart';
import 'package:finamp/services/finamp_settings_helper.dart';
import 'package:finamp/services/jellyfin_api_helper.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> askBeforeDeleteDownloadFromDevice(
    BuildContext context, DownloadStub stub) async {
  String type = stub.baseItemType.name;
  await showDialog(
      context: context,
      builder: (context) => ConfirmationPromptDialog(
          promptText: AppLocalizations.of(context)!
              .deleteFromTargetDialogText("", "device", type),
          confirmButtonText: AppLocalizations.of(context)!
              .deleteFromTargetConfirmButton("device"),
          abortButtonText: AppLocalizations.of(context)!.genericCancel,
          onConfirmed: () async {
            try {
              await GetIt.instance<DownloadsService>().deleteDownload(stub: stub);
              GlobalSnackbar
                .message((_) => AppLocalizations.of(context)!
                      .itemDeletedSnackbar("device", type)
                );

              if (context.mounted && FinampSettingsHelper.finampSettings.isOffline) {
                Navigator.of(context).popUntil((route) {
                  return route.settings.name != null // unnamed dialog
                      &&
                      route.settings.name !=
                          AlbumScreen.routeName; // albums screen
                });
              }
            } catch (err) {
              GlobalSnackbar.error(err);
            }
          },
          onAborted: () {},
          centerText: true));
}

Future<void> askBeforeDeleteFromServerAndDevice(
    BuildContext context, DownloadStub stub, {bool popIt = false}) async {
  DownloadItemStatus status =
      GetIt.instance<DownloadsService>().getStatus(stub, null);
  String type = stub.baseItemType.name;

  final jellyfinApiHelper = GetIt.instance<JellyfinApiHelper>();
  final downloadsService = GetIt.instance<DownloadsService>();

  String deleteType = status.isRequired
      ? "canDelete"
      : (status != DownloadItemStatus.notNeeded
          ? "cantDelete"
          : "notDownloaded");

  await showDialog(
      context: context,
      builder: (_) => ConfirmationPromptDialog(
          promptText: AppLocalizations.of(context)!
              .deleteFromTargetDialogText(deleteType, "server", type),
          confirmButtonText: AppLocalizations.of(context)!
              .deleteFromTargetConfirmButton("server"),
          abortButtonText: AppLocalizations.of(context)!.genericCancel,
          onConfirmed: () async {
            try {

              await jellyfinApiHelper.deleteItem(stub.id);
              GlobalSnackbar
                .message((_) => AppLocalizations.of(context)!
                      .itemDeletedSnackbar("server", type)
                );

              if (status.isRequired) {
                
                await downloadsService.deleteDownload(stub: stub);
                GlobalSnackbar
                  .message((_) => AppLocalizations.of(context)!
                        .itemDeletedSnackbar("device", type)
                  );
              }

              if (context.mounted) {
                Navigator.of(context).popUntil((route) {
                  return route.settings.name != null // unnamed dialog
                      &&
                      route.settings.name !=
                          AlbumScreen.routeName; // albums screen
                });
              }

            } catch (err) {
              GlobalSnackbar.error(err);
            }
          },
          onAborted: () {},
          centerText: true
      ));
}
