import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../data/services/api_client.dart';
import '../../../core/app_theme.dart';
import '../../../core/widgets/feedback_states.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool loading = true;
  String? error;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await context.read<ApiClient>().getJson(
        'api/notifications',
        query: {'page': '1', 'pageSize': '50'},
      ) as Map<String, dynamic>;
      if (mounted)
        setState(() => items = data['items'] as List<dynamic>? ?? []);
    } on ApiException catch (e) {
      if (mounted) setState(() => error = e.userMessage);
    } catch (_) {
      if (mounted)
        setState(() => error = 'Không tải được thông báo. Hãy thử lại.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> markRead(Map<String, dynamic> item) async {
    if (item['isRead'] == true) return;
    try {
      await context.read<ApiClient>().putJson(
        'api/notifications/${item['notificationId']}/read',
      );
      if (mounted) setState(() => item['isRead'] = true);
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.userMessage)));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể cập nhật thông báo.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Thông báo'),
      actions: [
        IconButton(
          tooltip: 'Làm mới thông báo',
          onPressed: load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: loading
        ? const LoadingState()
        : error != null
        ? ErrorPanel(message: error!, onRetry: load)
        : items.isEmpty
        ? const EmptyState(
            title: 'Chưa có thông báo',
            message: 'Thông tin đơn hàng và khuyến mãi sẽ hiển thị tại đây.',
            icon: Icons.notifications_none,
          )
        : RefreshIndicator(
            onRefresh: load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index] as Map<String, dynamic>;
                final createdAt = DateTime.tryParse('${item['createdAt']}');
                final dateLabel = createdAt == null
                    ? ''
                    : DateFormat('dd/MM/yyyy · HH:mm')
                          .format(createdAt.toLocal());
                return Card(
                  color: item['isRead'] == true
                      ? Colors.white
                      : PawmartColors.greenPale,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    onTap: () => markRead(item),
                    leading: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(
                        item['isRead'] == true
                            ? Icons.notifications_none
                            : Icons.notifications_active_outlined,
                        color: PawmartColors.green,
                      ),
                    ),
                    title: Text(
                      '${item['title']}',
                      style: TextStyle(
                        fontWeight: item['isRead'] == true
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('${item['message']}'),
                        if (dateLabel.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            dateLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              color: PawmartColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
  );
}
