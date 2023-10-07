import 'package:budget/database/tables.dart';
import 'package:budget/functions.dart';
import 'package:budget/pages/addWalletPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/animatedExpanded.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/openContainerNavigation.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/pages/walletDetailsPage.dart';
import 'package:budget/colors.dart';
import 'package:provider/provider.dart';
import 'package:budget/widgets/countNumber.dart';

class WalletEntry extends StatelessWidget {
  const WalletEntry({super.key, required this.wallet, required this.selected});
  final TransactionWallet wallet;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 6, right: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: boxShadowCheck(boxShadowGeneral(context)),
      ),
      child: OpenContainerNavigation(
        borderRadius: 15,
        openPage: WatchedWalletDetailsPage(walletPk: wallet.walletPk),
        button: (openContainer) {
          return Tappable(
            color: getColor(context, "lightDarkAccentHeavyLight"),
            borderRadius: 14,
            child: AnimatedContainer(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  width: 2,
                  color: selected
                      ? HexColor(wallet.colour,
                              defaultColor:
                                  Theme.of(context).colorScheme.primary)
                          .withOpacity(0.7)
                      : Colors.transparent,
                ),
              ),
              duration: Duration(milliseconds: 450),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      right: -11,
                      top: -5,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: HexColor(wallet.colour,
                                  defaultColor:
                                      Theme.of(context).colorScheme.primary)
                              .withOpacity(0.7),
                        ),
                        width: 20,
                        height: 20,
                      ),
                    ),
                    Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 17),
                            child: TextFont(
                              text: wallet.name,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          StreamBuilder<double?>(
                            stream: database.watchTotalOfWalletNoConversion(
                              wallet.walletPk,
                            ),
                            builder: (context, snapshot) {
                              return CountNumber(
                                lazyFirstRender: false,
                                count: (snapshot.data ?? 0 * -1),
                                duration: Duration(milliseconds: 1000),
                                decimals: wallet.decimals,
                                initialCount: (snapshot.data ?? 0 * -1),
                                textBuilder: (number) {
                                  return TextFont(
                                    textAlign: TextAlign.left,
                                    text: convertToMoney(
                                      Provider.of<AllWallets>(context),
                                      number,
                                      finalNumber: snapshot.data ?? 0 * -1,
                                      currencyKey: wallet.currency,
                                      decimals: wallet.decimals,
                                      addCurrencyName: true,
                                    ),
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  );
                                },
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
                                return SizedBox();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            onTap: () async {
              if (selected) {
                openContainer();
              } else {
                setPrimaryWallet(wallet.walletPk);
              }
            },
            onLongPress: () {
              pushRoute(
                  context,
                  AddWalletPage(
                    wallet: wallet,
                    routesToPopAfterDelete: RoutesToPopAfterDelete.All,
                  ));
            },
          );
        },
      ),
    );
  }
}

class WalletEntryRow extends StatelessWidget {
  const WalletEntryRow(
      {super.key, required this.wallet, required this.selected});
  final TransactionWallet wallet;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return OpenContainerNavigation(
      borderRadius: 15,
      openPage: WatchedWalletDetailsPage(walletPk: wallet.walletPk),
      button: (openContainer) {
        return Tappable(
          color: getColor(context, "lightDarkAccentHeavyLight"),
          borderRadius: 14,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Container(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        ScaledAnimatedSwitcher(
                          keyToWatch: selected.toString(),
                          child: selected
                              ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(100),
                                    color: HexColor(wallet.colour,
                                            defaultColor: Theme.of(context)
                                                .colorScheme
                                                .primary)
                                        .withOpacity(0.7),
                                  ),
                                  width: 20,
                                  height: 20,
                                )
                              : Transform.scale(
                                  scale: 0.9,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        width: 2,
                                        color: HexColor(wallet.colour,
                                                defaultColor: Theme.of(context)
                                                    .colorScheme
                                                    .primary)
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                    width: 20,
                                    height: 20,
                                  ),
                                ),
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: 17,
                              left: 10,
                            ),
                            child: TextFont(
                              text: wallet.name,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<double?>(
                    stream: database.watchTotalOfWalletNoConversion(
                      wallet.walletPk,
                    ),
                    builder: (context, snapshot) {
                      return CountNumber(
                        lazyFirstRender: false,
                        count: (snapshot.data ?? 0 * -1),
                        duration: Duration(milliseconds: 1000),
                        decimals: wallet.decimals,
                        initialCount: (snapshot.data ?? 0 * -1),
                        textBuilder: (number) {
                          return TextFont(
                            textAlign: TextAlign.right,
                            text: convertToMoney(
                              Provider.of<AllWallets>(context),
                              number,
                              finalNumber: snapshot.data ?? 0 * -1,
                              currencyKey: wallet.currency,
                              decimals: wallet.decimals,
                              addCurrencyName: true,
                            ),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          onTap: () async {
            if (selected) {
              openContainer();
            } else {
              setPrimaryWallet(wallet.walletPk);
            }
          },
          onLongPress: () {
            pushRoute(
                context,
                AddWalletPage(
                  wallet: wallet,
                  routesToPopAfterDelete: RoutesToPopAfterDelete.All,
                ));
          },
        );
      },
    );
  }
}

// set selectedWallet, update selectedWallet
Future<bool> setPrimaryWallet(String walletPk) async {
  await updateSettings("selectedWalletPk", walletPk, updateGlobalState: true);
  return true;
}
