import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Counter bumped whenever an external 401 forces the session to terminate.
///
/// Lives in its own file (with no dependencies on auth controllers/
/// repositories) so it can be safely imported by the network layer
/// (`api_client.dart`) without re-introducing the provider cycle:
/// `api_client → auth_controller → auth_repository → api_client`.
final authSessionEventProvider = StateProvider<int>((ref) => 0);
