import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'network_logger.dart';

/// Screen that shows network logs using ExpansionTile.
///
/// - Independent: does not require any external state management
/// - Works for both http and dio (logs are just data)
/// - Can be dropped into any host app or exposed directly from this package
class NetworkLogScreen extends StatefulWidget {
  const NetworkLogScreen({super.key});

  @override
  State<NetworkLogScreen> createState() => _NetworkLogScreenState();
}

class _NetworkLogScreenState extends State<NetworkLogScreen> {
  late List<NetworkLogModel> _logs;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    _logs = NetworkLogStorage.instance.getLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              setState(_refreshLogs);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear logs',
            onPressed: () {
              setState(() {
                NetworkLogStorage.instance.clear();
                _refreshLogs();
              });
            },
          ),
        ],
      ),
      body: _logs.isEmpty
          ? const Center(
              child: Text(
                'No network logs yet',
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return _buildLogTile(context, log);
              },
            ),
    );
  }

  Widget _buildLogTile(BuildContext context, NetworkLogModel log) {
    final uri = Uri.tryParse(log.url);
    final path = uri?.path.isNotEmpty == true ? uri!.path : log.url;
    final methodColor = _methodColor(log.method);
    final timeString = _formatTime(log.timestamp);
    final durationString = _formatDuration(log.duration);
    final curlCommand = _buildCurlCommand(log);

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: methodColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          log.method.toUpperCase(),
          style: TextStyle(
            color: methodColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        path,
        style: const TextStyle(fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          Text(
            timeString,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 12),
          Text(
            durationString,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 12),
          Text(
            'Status: ${log.statusCode}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _statusColor(log.statusCode),
                ),
          ),
        ],
      ),
      children: [
        _buildDetailRow('Full URL', log.url),
        const Divider(),
        _buildJsonSection(
          context: context,
          label: 'Request headers',
          data: log.requestHeaders,
        ),
        const Divider(),
        _buildJsonSection(
          context: context,
          label: 'Request body',
          data: log.requestBody,
          copyLabel: 'Copy request body',
        ),
        const Divider(),
        _buildJsonSection(
          context: context,
          label: 'Response headers',
          data: log.responseHeaders,
        ),
        const Divider(),
        _buildJsonSection(
          context: context,
          label: 'Response body',
          data: log.responseBody,
          copyLabel: 'Copy response body',
        ),
        const Divider(),
        _buildDetailRow('Status code', log.statusCode.toString()),
        _buildDetailRow('Time taken', durationString),
        const Divider(),
        _buildCurlSection(context, curlCommand),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonSection({
    required BuildContext context,
    required String label,
    required dynamic data,
    String? copyLabel,
  }) {
    final pretty = _prettyPrintJson(data);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (copyLabel != null && pretty.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: copyLabel,
                onPressed: () => _copyToClipboard(
                  context: context,
                  text: pretty,
                  message: '$label copied to clipboard',
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText(
            pretty.isEmpty ? '<empty>' : pretty,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCurlSection(BuildContext context, String curlCommand) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'cURL',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              tooltip: 'Copy cURL',
              onPressed: () => _copyToClipboard(
                context: context,
                text: curlCommand,
                message: 'cURL command copied to clipboard',
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText(
            curlCommand,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _copyToClipboard({
    required BuildContext context,
    required String text,
    required String message,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // --- Helpers ---

  Color _methodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return Colors.green;
      case 'POST':
        return Colors.blue;
      case 'PUT':
        return Colors.orange;
      case 'DELETE':
        return Colors.red;
      case 'PATCH':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _statusColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) return Colors.green;
    if (statusCode >= 300 && statusCode < 400) return Colors.blueGrey;
    if (statusCode >= 400 && statusCode < 500) return Colors.orange;
    return Colors.red;
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDuration(Duration d) {
    if (d.inMilliseconds < 1000) {
      return '${d.inMilliseconds} ms';
    }
    final seconds = d.inMilliseconds / 1000.0;
    return '${seconds.toStringAsFixed(2)} s';
  }

  String _prettyPrintJson(dynamic data) {
    if (data == null) return '';
    dynamic value = data;

    // If it's a string, try to decode JSON.
    if (value is String) {
      final trimmed = value.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try {
          value = jsonDecode(trimmed);
        } catch (_) {
          // not valid JSON, keep as string
          return value;
        }
      } else {
        return value;
      }
    }

    if (value is Map || value is List) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(value);
    }

    // Fallback
    return value.toString();
  }

  String _buildCurlCommand(NetworkLogModel log) {
    final buffer = StringBuffer();
    buffer.write('curl -X ${log.method.toUpperCase()}');

    // Headers
    log.requestHeaders.forEach((key, value) {
      buffer.write(" -H '${_escapeSingleQuotes('$key: $value')}'");
    });

    // Body
    final body = log.requestBody;
    if (body != null) {
      String bodyString;
      if (body is String) {
        bodyString = body;
      } else {
        bodyString = jsonEncode(body);
      }
      buffer.write(" --data '${_escapeSingleQuotes(bodyString)}'");
    }

    buffer.write(" '${_escapeSingleQuotes(log.url)}'");

    return buffer.toString();
  }

  String _escapeSingleQuotes(String input) {
    // Simple escape for single quotes inside single-quoted strings.
    return input.replaceAll("'", r"'\''");
  }
}

