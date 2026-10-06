import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';

class FriendsScreen extends StatefulWidget {
  final VoidCallback onGoBack;

  const FriendsScreen({super.key, required this.onGoBack});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _friends = [];
  List<dynamic> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/api/friends/');
      if (res is List) {
        setState(() {
          _friends = res;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    try {
      final res = await _apiClient.get('/api/friends/search?q=${Uri.encodeComponent(query.trim())}');
      if (res is List) {
        setState(() {
          _searchResults = res;
          _isSearching = false;
        });
        return;
      }
    } catch (_) {}

    setState(() => _isSearching = false);
  }

  Future<void> _addFriend(String username) async {
    try {
      final res = await _apiClient.post('/api/friends/add', {'target_username': username});
      final msg = res['message'] ?? '$username eklendi!';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.green,
            content: Text(msg, style: const TextStyle(color: AppColors.white)),
          ),
        );
      }
      _fetchFriends();
      if (_searchController.text.isNotEmpty) {
        _searchUsers(_searchController.text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(e.toString().replaceAll('Exception: ', ''), style: const TextStyle(color: AppColors.white)),
          ),
        );
      }
    }
  }

  Future<void> _removeFriend(int friendId, String username) async {
    try {
      await _apiClient.delete('/api/friends/$friendId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.cardNavy,
            content: Text('$username arkadaş listenizden çıkarıldı', style: const TextStyle(color: AppColors.yellow)),
          ),
        );
      }
      _fetchFriends();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _searchBar(),
            Expanded(
              child: _searchController.text.trim().isNotEmpty
                  ? _buildSearchResults()
                  : _buildFriendsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onGoBack,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.cardNavy,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.arrow_back, color: AppColors.white, size: 26),
            ),
          ),
          const Text(
            'Arkadaşlarım',
            style: TextStyle(
              color: AppColors.yellow,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          GestureDetector(
            onTap: _fetchFriends,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.cardNavy,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(Icons.refresh, color: AppColors.blue, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        controller: _searchController,
        onChanged: _searchUsers,
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          hintText: 'Kullanıcı adı ile arkadaş ara...',
          hintStyle: const TextStyle(color: AppColors.grey),
          prefixIcon: const Icon(Icons.search, color: AppColors.yellow),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _searchUsers('');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.cardNavy,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.yellow),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.person_search, color: AppColors.grey, size: 64),
            SizedBox(height: 12),
            Text('Sonuç bulunamadı', style: TextStyle(color: AppColors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _searchResults.length,
      itemBuilder: (ctx, index) {
        final item = _searchResults[index];
        final username = item['username']?.toString() ?? '';
        final level = item['level'] ?? 1;
        final xp = item['xp'] ?? 0;
        final isFriend = item['is_friend'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardNavy,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.blue,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seviye $level • $xp XP',
                      style: const TextStyle(color: AppColors.yellow, fontSize: 13),
                    ),
                  ],
                ),
              ),
              isFriend
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.green.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.green),
                      ),
                      child: const Text('Arkadaş', style: TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.person_add, color: AppColors.darkNavy, size: 18),
                      label: const Text('Ekle', style: TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.bold)),
                      onPressed: () => _addFriend(username),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFriendsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
    }
    if (_friends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.people_outline, color: AppColors.grey, size: 74),
              const SizedBox(height: 16),
              const Text(
                'Henüz arkadaşın yok!',
                style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Yukarıdaki arama çubuğundan diğer öğrencileri bulup ekleyebilir, puanlarını takip edebilirsin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.person_add, color: AppColors.white),
                label: const Text('Admin’i Arkadaş Ekle', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold)),
                onPressed: () => _addFriend('Admin'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _friends.length,
      itemBuilder: (ctx, index) {
        final item = _friends[index];
        final friend = item['friend'] as Map<String, dynamic>? ?? {};
        final friendId = friend['id'] as int? ?? 0;
        final username = friend['username']?.toString() ?? 'Kullanıcı';
        final level = friend['level'] ?? 1;
        final xp = friend['xp'] ?? 0;
        final bio = friend['bio']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardNavy,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.yellow,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.darkNavy, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            username,
                            style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 17),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withAlpha(40),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.blue),
                          ),
                          child: Text('Lv. $level', style: const TextStyle(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$xp XP',
                      style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.grey, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent, size: 22),
                tooltip: 'Arkadaşı Çıkar',
                onPressed: () => _removeFriend(friendId, username),
              ),
            ],
          ),
        );
      },
    );
  }
}
