import 'package:askaide/helper/helper.dart';
import 'package:askaide/lang/lang.dart';
import 'package:askaide/page/component/background_container.dart';
import 'package:askaide/page/component/coin.dart';
import 'package:askaide/page/component/theme/custom_size.dart';
import 'package:askaide/page/component/theme/custom_theme.dart';
import 'package:askaide/repo/api/quota.dart';
import 'package:askaide/repo/api_server.dart';
import 'package:askaide/repo/settings_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final SettingRepository setting;
  const PaymentHistoryScreen({super.key, required this.setting});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    var customColors = Theme.of(context).extension<CustomColors>()!;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: CustomSize.toolbarHeight,
        title: const Text(
          '购买历史',
          style: TextStyle(fontSize: CustomSize.appBarTitleSize),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: customColors.backgroundContainerColor,
      body: BackgroundContainer(
        setting: widget.setting,
        enabled: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder(
            future: APIServer().quotaDetails(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 50,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        resolveError(context, snapshot.error!),
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              return _buildQuotaDetailPage(
                  context, snapshot.data!, customColors);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildQuotaDetailPage(
      BuildContext context, QuotaResp quota, CustomColors customColors) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (var item in quota.details)
                Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.only(
                        top: 20,
                        bottom: 10,
                        left: 16,
                        right: 16,
                      ),
                      decoration: BoxDecoration(
                        color: customColors.paymentItemBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (item.note == null || item.note == '')
                                          ? '购买'
                                          : item.note!,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      DateFormat(
                                        'yyyy/MM/dd HH:mm',
                                      ).format(item.createdAt.toLocal()),
                                      textScaleFactor: 0.8,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Coin(
                                    count: item.quota,
                                    color: Colors.amber,
                                    withAddPrefix: true,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  Text(
                                    '${DateFormat('yyyy/MM/dd').format(item.periodEndAt.toLocal())} 过期',
                                    textScaleFactor: 0.7,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildTagForItem(item),
                  ],
                )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagForItem(QuotaDetail item) {
    if (item.rest <= 0) {
      return _buildTag(AppLocale.usedUp.getString(context), Colors.orange);
    }

    if (item.expired) {
      return _buildTag(AppLocale.expired.getString(context), Colors.grey[600]!);
    }

    return const SizedBox();
  }

  Widget _buildTag(String text, Color color) {
    return Positioned(
      right: 1,
      top: 7,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(9),
            bottomLeft: Radius.circular(9),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 2,
        ),
        child: Text(
          text,
          textScaleFactor: 0.6,
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
