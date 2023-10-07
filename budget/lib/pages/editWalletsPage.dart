import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/main.dart';
import 'package:budget/pages/addWalletPage.dart';
import 'package:budget/pages/editBudgetPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/fab.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/framework/popupFramework.dart';
import 'package:budget/widgets/globalSnackBar.dart';
import 'package:budget/widgets/noResults.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/framework/pageFramework.dart';
import 'package:budget/widgets/radioItems.dart';
import 'package:budget/widgets/settingsContainers.dart';
import 'package:budget/widgets/textInput.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/walletEntry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' hide SliverReorderableList;
import 'package:flutter/services.dart' hide TextInput;
import 'package:budget/widgets/editRowEntry.dart';
import 'package:budget/modified/reorderable_list.dart';
import 'package:provider/provider.dart';
import 'exchangeRatesPage.dart';

class EditWalletsPage extends StatefulWidget {
  EditWalletsPage({
    Key? key,
  }) : super(key: key);

  @override
  _EditWalletsPageState createState() => _EditWalletsPageState();
}

class _EditWalletsPageState extends State<EditWalletsPage> {
  bool dragDownToDismissEnabled = true;
  int currentReorder = -1;
  String searchValue = "";

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      database.fixOrderWallets();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (searchValue != "") {
          setState(() {
            searchValue = "";
          });
          return false;
        } else {
          return true;
        }
      },
      child: PageFramework(
        horizontalPadding: getHorizontalPaddingConstrained(context),
        dragDownToDismiss: true,
        dragDownToDismissEnabled: dragDownToDismissEnabled,
        scrollToTopButton: true,
        title: "edit-accounts".tr(),
        floatingActionButton: AnimateFABDelayed(
          fab: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom),
            child: FAB(
              tooltip: "add-account".tr(),
              openPage: AddWalletPage(
                routesToPopAfterDelete: RoutesToPopAfterDelete.None,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            padding: EdgeInsets.all(15),
            tooltip: "add-account".tr(),
            onPressed: () {
              pushRoute(
                context,
                AddWalletPage(
                  routesToPopAfterDelete: RoutesToPopAfterDelete.None,
                ),
              );
            },
            icon: Icon(appStateSettings["outlinedIcons"]
                ? Icons.add_outlined
                : Icons.add_rounded),
          ),
        ],
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextInput(
                labelText: "search-accounts-placeholder".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.search_outlined
                    : Icons.search_rounded,
                onSubmitted: (value) {
                  setState(() {
                    searchValue = value;
                  });
                },
                onChanged: (value) {
                  setState(() {
                    searchValue = value;
                  });
                },
                autoFocus: false,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedExpanded(
              expand: hideIfSearching(searchValue, context) == false,
              child: SettingsContainerOpenPage(
                onOpen: () {
                  checkIfExchangeRateChangeBefore();
                },
                onClosed: () {
                  checkIfExchangeRateChangeAfter();
                },
                openPage: ExchangeRates(),
                title: "exchange-rates".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.account_balance_wallet_outlined
                    : Icons.account_balance_wallet_rounded,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: AnimatedExpanded(
              expand: hideIfSearching(searchValue, context) == false,
              child: SettingsContainer(
                onTap: () {
                  openBottomSheet(
                    context,
                    fullSnap: true,
                    TransferBalancePopup(
                      wallet: Provider.of<AllWallets>(context, listen: false)
                          .indexedByPk[appStateSettings["selectedWalletPk"]]!,
                    ),
                  );
                },
                title: "transfer-balance".tr(),
                icon: appStateSettings["outlinedIcons"]
                    ? Icons.compare_arrows_outlined
                    : Icons.compare_arrows_rounded,
              ),
            ),
          ),
          StreamBuilder<List<TransactionWallet>>(
            stream: database.watchAllWallets(
                searchFor: searchValue == "" ? null : searchValue),
            builder: (context, snapshot) {
              if (snapshot.hasData && (snapshot.data ?? []).length <= 0) {
                return SliverToBoxAdapter(
                  child: NoResults(
                    message: "no-accounts-found".tr(),
                  ),
                );
              }
              if (snapshot.hasData && (snapshot.data ?? []).length > 0) {
                return SliverReorderableList(
                  onReorderStart: (index) {
                    HapticFeedback.heavyImpact();
                    setState(() {
                      dragDownToDismissEnabled = false;
                      currentReorder = index;
                    });
                  },
                  onReorderEnd: (_) {
                    setState(() {
                      dragDownToDismissEnabled = true;
                      currentReorder = -1;
                    });
                  },
                  itemBuilder: (context, index) {
                    TransactionWallet wallet = snapshot.data![index];
                    Color accentColor = dynamicPastel(
                        context,
                        HexColor(wallet.colour,
                            defaultColor:
                                Theme.of(context).colorScheme.primary),
                        amountLight: 0.55,
                        amountDark: 0.35);
                    return EditRowEntry(
                      extraIcon: appStateSettings["selectedWalletPk"] ==
                              wallet.walletPk
                          ? appStateSettings["outlinedIcons"]
                              ? Icons.star_outlined
                              : Icons.star_rounded
                          : Icons.star_outline,
                      onExtra: () async {
                        setPrimaryWallet(wallet.walletPk);
                      },
                      canDelete: (wallet.walletPk != "0"),
                      canReorder: searchValue == "" &&
                          (snapshot.data ?? []).length != 1,
                      currentReorder:
                          currentReorder != -1 && currentReorder != index,
                      index: index,
                      accentColor: accentColor,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFont(
                            text: wallet.name,
                            fontWeight: FontWeight.bold,
                            fontSize: 21,
                          ),
                          Container(height: 2),
                          StreamBuilder<double?>(
                            stream: database.watchTotalOfWalletNoConversion(
                              wallet.walletPk,
                            ),
                            builder: (context, snapshot) {
                              return TextFont(
                                textAlign: TextAlign.left,
                                text: convertToMoney(
                                  Provider.of<AllWallets>(context),
                                  snapshot.data ?? 0 * -1,
                                  currencyKey: wallet.currency,
                                  decimals: wallet.decimals,
                                  addCurrencyName: true,
                                ).toString(),
                                fontSize: 15,
                              );
                            },
                          ),
                          StreamBuilder<List<int?>>(
                            stream: database
                                .watchTotalCountOfTransactionsInWallet(
                                    [wallet.walletPk]),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return TextFont(
                                  textAlign: TextAlign.left,
                                  text: snapshot.data![0].toString() +
                                      " " +
                                      (snapshot.data![0] == 1
                                          ? "transaction".tr().toLowerCase()
                                          : "transactions".tr().toLowerCase()),
                                  fontSize: 14,
                                  textColor: getColor(context, "black")
                                      .withOpacity(0.65),
                                );
                              } else {
                                return TextFont(
                                    textAlign: TextAlign.left,
                                    text: "/ transactions",
                                    fontSize: 14,
                                    textColor: getColor(context, "black")
                                        .withOpacity(0.65));
                              }
                            },
                          ),
                        ],
                      ),
                      onDelete: () async {
                        return (await deleteWalletPopup(
                              context,
                              wallet: wallet,
                              routesToPopAfterDelete:
                                  RoutesToPopAfterDelete.None,
                            )) ==
                            DeletePopupAction.Delete;
                      },
                      openPage: AddWalletPage(
                          wallet: wallet,
                          routesToPopAfterDelete: RoutesToPopAfterDelete.One),
                      key: ValueKey(wallet.walletPk),
                    );
                  },
                  itemCount: snapshot.data!.length,
                  onReorder: (_intPrevious, _intNew) async {
                    TransactionWallet oldWallet = snapshot.data![_intPrevious];

                    if (_intNew > _intPrevious) {
                      await database.moveWallet(
                          oldWallet.walletPk, _intNew - 1, oldWallet.order);
                    } else {
                      await database.moveWallet(
                          oldWallet.walletPk, _intNew, oldWallet.order);
                    }
                    return true;
                  },
                );
              }
              return SliverToBoxAdapter(
                child: Container(),
              );
            },
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: 85),
          ),
        ],
      ),
    );
  }
}

Future<DeletePopupAction?> deleteWalletPopup(
  BuildContext context, {
  required TransactionWallet wallet,
  required RoutesToPopAfterDelete routesToPopAfterDelete,
}) async {
  DeletePopupAction? action = await openDeletePopup(
    context,
    title: "delete-account-question".tr(),
    subtitle: wallet.name,
    description: "delete-account-question-description".tr(),
  );
  if (action == DeletePopupAction.Delete) {
    int transactionsFromWalletLength =
        (await database.getAllTransactionsFromWallet(wallet.walletPk)).length;
    dynamic result = true;
    if (transactionsFromWalletLength > 0) {
      result = await openPopup(
        context,
        title: "delete-all-transactions-question".tr(),
        description: "delete-account-merge-warning".tr(),
        icon: appStateSettings["outlinedIcons"]
            ? Icons.warning_outlined
            : Icons.warning_rounded,
        onCancel: () {
          Navigator.pop(context, false);
        },
        onCancelLabel: "cancel".tr(),
        onSubmit: () async {
          Navigator.pop(context, true);
        },
        onExtra2: () {
          Navigator.pop(context, false);
          mergeWalletPopup(
            context,
            walletOriginal: wallet,
            routesToPopAfterDelete: routesToPopAfterDelete,
          );
        },
        onExtraLabel2: "move-transactions".tr(),
        onSubmitLabel: "delete".tr(),
      );
    }
    if (result == true) {
      if (routesToPopAfterDelete == RoutesToPopAfterDelete.All) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (routesToPopAfterDelete == RoutesToPopAfterDelete.One) {
        Navigator.of(context).pop();
      }
      openLoadingPopupTryCatch(() async {
        await database.deleteWallet(wallet.walletPk, wallet.order);
        openSnackbar(
          SnackbarMessage(
            title: "deleted-account".tr(),
            icon: Icons.delete,
            description: wallet.name,
          ),
        );
      });
    }
  }
  return action;
}

void mergeWalletPopup(
  BuildContext context, {
  required TransactionWallet walletOriginal,
  required RoutesToPopAfterDelete routesToPopAfterDelete,
}) async {
  var selectedWalletResult = await selectWalletPopup(
    context,
    removeWalletPk: walletOriginal.walletPk,
    subtitle: "account-to-transfer-all-transactions-to".tr(),
  );
  if (selectedWalletResult != null) {
    final result = await openPopup(
      context,
      title: "merge-into".tr() + " " + selectedWalletResult.name + "?",
      description: "merge-into-description-accounts".tr(),
      icon: appStateSettings["outlinedIcons"]
          ? Icons.merge_outlined
          : Icons.merge_rounded,
      onSubmit: () async {
        Navigator.pop(context, true);
      },
      onSubmitLabel: "merge".tr(),
      onCancelLabel: "cancel".tr(),
      onCancel: () {
        Navigator.pop(context);
      },
    );
    if (result == true) {
      if (routesToPopAfterDelete == RoutesToPopAfterDelete.All) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (routesToPopAfterDelete == RoutesToPopAfterDelete.One) {
        Navigator.of(context).pop();
      }
      openLoadingPopupTryCatch(() async {
        await database.moveWalletTransactions(
          Provider.of<AllWallets>(context, listen: false),
          walletOriginal.walletPk,
          selectedWalletResult.walletPk,
        );
        try {
          await database.deleteWallet(
              walletOriginal.walletPk, walletOriginal.order);
        } catch (e) {
          openSnackbar(
            SnackbarMessage(
              title: "cannot-remove".tr(),
              description: "cannot-remove-default-account".tr(),
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.warning_outlined
                  : Icons.warning_rounded,
            ),
          );
        }
        openSnackbar(
          SnackbarMessage(
            title: "merged-account".tr(),
            icon: appStateSettings["outlinedIcons"]
                ? Icons.merge_outlined
                : Icons.merge_rounded,
            description:
                walletOriginal.name + " → " + selectedWalletResult.name,
          ),
        );
      });
    }
  }
}

Future<TransactionWallet?> selectWalletPopup(BuildContext context,
    {String? removeWalletPk,
    String? subtitle,
    TransactionWallet? selectedWallet}) async {
  dynamic wallet = await openBottomSheet(
    context,
    PopupFramework(
      title: "select-account".tr(),
      subtitle: subtitle,
      child: StreamBuilder<List<TransactionWallet>>(
        stream: database.watchAllWallets(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<TransactionWallet> walletsWithoutOneDeleted = snapshot.data!;
            if (removeWalletPk != null)
              walletsWithoutOneDeleted.removeWhere(
                  (TransactionWallet w) => w.walletPk == removeWalletPk);
            if (walletsWithoutOneDeleted.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: NoResults(message: "no-accounts-found".tr()),
              );
            }
            return RadioItems(
              items: walletsWithoutOneDeleted,
              colorFilter: (TransactionWallet? wallet) {
                if (wallet == null) return null;
                return dynamicPastel(
                  context,
                  lightenPastel(
                    HexColor(
                      wallet.colour,
                      defaultColor: Theme.of(context).colorScheme.primary,
                    ),
                    amount: 0.2,
                  ),
                  amount: 0.1,
                );
              },
              displayFilter: (TransactionWallet? wallet) {
                return (wallet?.name ?? "") +
                    " " +
                    "(" +
                    (wallet?.currency ?? "").allCaps +
                    ")";
              },
              initial: selectedWallet,
              onChanged: (TransactionWallet? wallet) async {
                Navigator.of(context).pop(wallet);
              },
            );
          } else {
            return SizedBox.shrink();
          }
        },
      ),
    ),
  );

  if (wallet is TransactionWallet) return wallet;
  return null;
}
