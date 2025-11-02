import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../services/mtn_sandbox_service.dart';

class MtnSandboxScreen extends StatefulWidget {
  const MtnSandboxScreen({super.key});

  @override
  State<MtnSandboxScreen> createState() => _MtnSandboxScreenState();
}

class _MtnSandboxScreenState extends State<MtnSandboxScreen> {
  final _service = MtnSandboxService();
  final _callbackHostCtrl = TextEditingController(text: 'https://example.com');

  String? _referenceId;
  String? _apiKey;
  String _log = '';
  bool _busy = false;

  void _appendLog(String line) {
    setState(() {
      _log = (_log.isEmpty ? line : '$_log\n$line');
    });
  }

  Future<void> _createApiUser() async {
    setState(() => _busy = true);
    try {
      final refId = const Uuid().v4();
      final usedRef = await _service.createApiUser(
        referenceId: refId,
        providerCallbackHost: _callbackHostCtrl.text.trim(),
      );
      setState(() => _referenceId = usedRef);
      _appendLog('API user created. X-Reference-Id: $usedRef');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API user created with ref: $usedRef')),
      );
    } catch (e) {
      _appendLog('Error creating API user: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createApiKey() async {
    if (_referenceId == null) {
      _appendLog('No referenceId. Create API user first.');
      return;
    }
    setState(() => _busy = true);
    try {
      final key = await _service.createApiKey(_referenceId!);
      setState(() => _apiKey = key);
      _appendLog('API key created: $key');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API key created')),
      );
    } catch (e) {
      _appendLog('Error creating API key: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _getApiUser() async {
    if (_referenceId == null) {
      _appendLog('No referenceId. Create API user first.');
      return;
    }
    setState(() => _busy = true);
    try {
      final info = await _service.getApiUser(_referenceId!);
      _appendLog('API user info: $info');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fetched API user info')), 
      );
    } catch (e) {
      _appendLog('Error fetching API user info: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _callbackHostCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MTN Sandbox (User Provisioning)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _callbackHostCtrl,
              decoration: const InputDecoration(
                labelText: 'providerCallbackHost',
                hintText: 'https://example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _busy ? null : _createApiUser,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Create API User'),
                ),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _createApiKey,
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Create API Key'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _getApiUser,
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Get API User'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_referenceId != null) Text('ReferenceId: $_referenceId'),
            if (_apiKey != null) Text('apiKey: $_apiKey'),
            const SizedBox(height: 12),
            const Text('Log:'),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(_log.isEmpty ? 'No logs yet.' : _log),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
