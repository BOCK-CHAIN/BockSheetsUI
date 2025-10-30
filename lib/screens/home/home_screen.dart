// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:mysheets/providers/theme_provider.dart';
import 'package:mysheets/services/file_service.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/spreadsheet_provider.dart';
import '../spreadsheet/spreadsheet_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  int _selectedIndex = 0;
  Set<String> _starredSheets = {}; // Track starred spreadsheets

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpreadsheetProvider>().loadSpreadsheets();
    });
  }

  void _createNewSpreadsheet() async {
    final controller = TextEditingController(text: 'Untitled Spreadsheet');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Spreadsheet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Spreadsheet Name',
            hintText: 'Enter a name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final provider = context.read<SpreadsheetProvider>();
      final spreadsheetId = await provider.createSpreadsheet(title: result);
      
      if (spreadsheetId != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SpreadsheetScreen(
              spreadsheetId: spreadsheetId,
              title: result,
            ),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredSheets(List<Map<String, dynamic>> allSheets) {
    // Apply search filter
    var filtered = allSheets.where((sheet) {
      final title = sheet['title']?.toString().toLowerCase() ?? '';
      return title.contains(_searchQuery.toLowerCase());
    }).toList();

    // Apply category filter based on selected index
    switch (_selectedIndex) {
      case 0: // Home - All non-deleted sheets
        return filtered.where((sheet) => sheet['is_deleted'] != true).toList();
      case 1: // Starred - Non-deleted starred sheets
        return filtered.where((sheet) => 
          _starredSheets.contains(sheet['id']) && sheet['is_deleted'] != true
        ).toList();
      case 2: // Shared (not implemented yet)
        return [];
      case 3: // Trash - Only deleted sheets
        return filtered.where((sheet) => sheet['is_deleted'] == true).toList();
      default:
        return filtered.where((sheet) => sheet['is_deleted'] != true).toList();
    }
  }

  void _toggleStar(String sheetId) {
    setState(() {
      if (_starredSheets.contains(sheetId)) {
        _starredSheets.remove(sheetId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from starred'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _starredSheets.add(sheetId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to starred'),
            duration: Duration(seconds: 2),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar Navigation
          NavigationRail(
            extended: MediaQuery.of(context).size.width > 800,
            backgroundColor: AppTheme.surfaceLight,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.grid_on_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.star_outline),
                selectedIcon: Icon(Icons.star),
                label: Text('Starred'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Shared'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.delete_outline),
                selectedIcon: Icon(Icons.delete),
                label: Text('Trash'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top App Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: AppTheme.subtleShadow,
                  ),
                  child: Row(
                    children: [
                      // Search Bar
                      Expanded(
                        flex: 2,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: TextField(
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Search spreadsheets...',
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: AppTheme.backgroundLight,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      
                      // User Menu
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No new notifications'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        tooltip: 'Notifications',
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () {
                          _showSettingsDialog();
                        },
                        tooltip: 'Settings',
                      ),
                      const SizedBox(width: 8),
                      
                      // User Profile
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          final username = authProvider.profile?['username'] ?? 
                                         authProvider.user?.email?.substring(0, 1) ?? 'U';
                          return PopupMenuButton<int>(
                            child: CircleAvatar(
                              backgroundColor: AppTheme.primaryViolet,
                              child: Text(
                                username[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            onSelected: (value) async {
                              if (value == 1) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                );
                              } else if (value == 2) {
                                await authProvider.signOut();
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                }
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem<int>(
                                value: -1,
                                enabled: false,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      authProvider.user?.email ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      authProvider.profile?['username'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<int>(
                                value: 1,
                                child: Row(
                                  children: [
                                    Icon(Icons.person_outline),
                                    SizedBox(width: 12),
                                    Text('Profile'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<int>(
                                value: 2,
                                child: Row(
                                  children: [
                                    Icon(Icons.logout, color: AppTheme.error),
                                    SizedBox(width: 12),
                                    Text('Sign Out', style: TextStyle(color: AppTheme.error)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Content Area
                Expanded(
                  child: Consumer<SpreadsheetProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final filteredSheets = _getFilteredSheets(provider.spreadsheets);
                      final categoryTitle = _getCategoryTitle();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      categoryTitle,
                                      style: Theme.of(context).textTheme.displaySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${filteredSheets.length} spreadsheets',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _createNewSpreadsheet,
                                      icon: const Icon(Icons.add),
                                      label: const Text('New Spreadsheet'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        _handleImport();
                                      },
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text('Import'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            
                            // Spreadsheet Grid or Empty State
                            filteredSheets.isEmpty
                                ? _buildEmptyState()
                                : GridView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 300,
                                      childAspectRatio: 0.95, // Adjusted for taller cards
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                    ),
                                    itemCount: filteredSheets.length,
                                    itemBuilder: (context, index) {
                                      return _buildSpreadsheetCard(filteredSheets[index]);
                                    },
                                    
                                  ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'My Spreadsheets';
      case 1:
        return 'Starred';
      case 2:
        return 'Shared with Me';
      case 3:
        return 'Trash';
      default:
        return 'My Spreadsheets';
    }
  }

  Widget _buildSpreadsheetCard(Map<String, dynamic> sheet) {
    final isStarred = _starredSheets.contains(sheet['id']);
    final isDeleted = sheet['is_deleted'] == true;
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: isDeleted ? null : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SpreadsheetScreen(
                    spreadsheetId: sheet['id'],
                    title: sheet['title'],
                  ),
                ),
              );
            },
            onHover: (hovering) {
              // This triggers the InkWell's hover animation
            },
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Preview Area - Fixed height
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: isDeleted 
                          ? LinearGradient(
                              colors: [Colors.grey.shade400, Colors.grey.shade500]
                            )
                          : AppTheme.accentGradient,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Center(
                        child: Icon(
                          isDeleted ? Icons.delete_outline : Icons.table_chart,
                          size: 56,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                    
                    // Content Area - Fixed padding and layout
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title - Fixed height for 2 lines
                          SizedBox(
                            height: 44,
                            child: Text(
                              sheet['title'] ?? 'Untitled',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                                color: isDeleted ? AppTheme.textMuted : null,
                                decoration: isDeleted ? TextDecoration.lineThrough : null,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Timestamp and Actions Row
                          Row(
                            children: [
                              Icon(
                                isDeleted ? Icons.delete_sweep : Icons.access_time,
                                size: 14,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  isDeleted 
                                    ? 'Deleted ${_formatDate(DateTime.parse(sheet['updated_at']))}'
                                    : _formatDate(DateTime.parse(sheet['updated_at'])),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              
                              if (!isDeleted) ...[
                                // Star Button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _toggleStar(sheet['id']),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        isStarred ? Icons.star : Icons.star_outline,
                                        size: 20,
                                        color: isStarred ? Colors.amber : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // More Menu Button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showOptions(context, sheet),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.more_vert,
                                        size: 20,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                // Restore Button for deleted items
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _restoreSpreadsheet(sheet),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.restore_from_trash,
                                        size: 20,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Permanent Delete Button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _permanentlyDelete(sheet),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.delete_forever,
                                        size: 20,
                                        color: AppTheme.error,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title, subtitle;
    IconData icon;

    switch (_selectedIndex) {
      case 1:
        title = 'No starred spreadsheets';
        subtitle = 'Star your favorite spreadsheets for quick access';
        icon = Icons.star_outline;
        break;
      case 2:
        title = 'No shared spreadsheets';
        subtitle = 'Spreadsheets shared with you will appear here';
        icon = Icons.people_outline;
        break;
      case 3:
        title = 'Trash is empty';
        subtitle = 'Deleted spreadsheets will appear here';
        icon = Icons.delete_outline;
        break;
      default:
        title = 'No spreadsheets found';
        subtitle = _searchQuery.isEmpty 
            ? 'Create your first spreadsheet to get started'
            : 'No spreadsheets match your search';
        icon = Icons.description_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 60),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.cellHover,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              icon,
              size: 60,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          if (_selectedIndex == 0 && _searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createNewSpreadsheet,
              icon: const Icon(Icons.add),
              label: const Text('Create Spreadsheet'),
            ),
          ],
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, Map<String, dynamic> sheet) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(sheet);
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_copy),
                title: const Text('Make a copy'),
                onTap: () {
                  Navigator.pop(context);
                  _duplicateSpreadsheet(sheet);
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Share feature coming soon')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text('Export'),
                onTap: () {
                  Navigator.pop(context);
                  _showExportOptions(sheet);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.error),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleDelete(sheet);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _restoreSpreadsheet(Map<String, dynamic> sheet) async {
    print('Restoring spreadsheet: ${sheet['title']}');
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Restoring spreadsheet...'),
          ],
        ),
      ),
    );
    
    try {
      final provider = context.read<SpreadsheetProvider>();
      final success = await provider.restoreSpreadsheet(sheet['id']);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spreadsheet restored successfully'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to restore spreadsheet'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error restoring spreadsheet: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _permanentlyDelete(Map<String, dynamic> sheet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete'),
        content: Text(
          'Are you sure you want to permanently delete "${sheet['title']}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Permanently deleting...'),
          ],
        ),
      ),
    );
    
    try {
      final provider = context.read<SpreadsheetProvider>();
      final success = await provider.permanentlyDeleteSpreadsheet(sheet['id']);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (!mounted) return;
      
      if (success) {
        if (_starredSheets.contains(sheet['id'])) {
          setState(() {
            _starredSheets.remove(sheet['id']);
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spreadsheet permanently deleted'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to delete permanently'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting permanently: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _handleDelete(Map<String, dynamic> sheet) async {
    print('_handleDelete called for: ${sheet['title']} (${sheet['id']})');
    
    final confirmed = await _showDeleteConfirmation(sheet['title']);
    print('Delete confirmed: $confirmed');
    
    if (confirmed != true) {
      print('Delete cancelled by user');
      return;
    }
    
    if (!mounted) {
      print('Widget not mounted, aborting delete');
      return;
    }
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Deleting spreadsheet...'),
          ],
        ),
      ),
    );
    
    try {
      print('Calling provider.deleteSpreadsheet...');
      final provider = context.read<SpreadsheetProvider>();
      final success = await provider.deleteSpreadsheet(sheet['id']);
      
      print('Delete result: $success');
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (!mounted) return;
      
      if (success) {
        print('Delete successful, removing from starred if needed');
        // Remove from starred if it was starred
        if (_starredSheets.contains(sheet['id'])) {
          setState(() {
            _starredSheets.remove(sheet['id']);
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spreadsheet deleted successfully'),
            backgroundColor: AppTheme.success,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        print('Delete failed: ${provider.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage ?? 'Failed to delete spreadsheet'),
            backgroundColor: AppTheme.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Exception during delete: $e');
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting spreadsheet: $e'),
          backgroundColor: AppTheme.error,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return AlertDialog(
            title: const Text('Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme Setting
                  ListTile(
                    leading: Icon(
                      themeProvider.isDarkMode 
                        ? Icons.dark_mode 
                        : Icons.light_mode,
                    ),
                    title: const Text('Theme'),
                    subtitle: Text(themeProvider.isDarkMode ? 'Dark' : 'Light'),
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                    ),
                  ),
                  
                  // Auto-save Setting
                  ListTile(
                    leading: const Icon(Icons.save),
                    title: const Text('Auto-save'),
                    subtitle: Text(
                      themeProvider.autoSave 
                        ? 'Every ${themeProvider.autoSaveInterval}s' 
                        : 'Disabled'
                    ),
                    trailing: Switch(
                      value: themeProvider.autoSave,
                      onChanged: (value) {
                        themeProvider.setAutoSave(value);
                      },
                    ),
                  ),
                  
                  // Auto-save Interval
                  if (themeProvider.autoSave)
                    ListTile(
                      leading: const Icon(Icons.timer),
                      title: const Text('Auto-save interval'),
                      subtitle: Slider(
                        value: themeProvider.autoSaveInterval.toDouble(),
                        min: 10,
                        max: 120,
                        divisions: 11,
                        label: '${themeProvider.autoSaveInterval}s',
                        onChanged: (value) {
                          themeProvider.setAutoSaveInterval(value.toInt());
                        },
                      ),
                    ),
                  
                  // Language Setting
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Language'),
                    subtitle: Text(_getLanguageName(themeProvider.language)),
                    onTap: () {
                      _showLanguageSelector(themeProvider);
                    },
                  ),
                  
                  const Divider(),
                  
                  // Help & Support
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & Support'),
                    onTap: () {
                      Navigator.pop(context);
                      _showHelpDialog();
                    },
                  ),
                  
                  // About
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    onTap: () {
                      Navigator.pop(context);
                      showAboutDialog(
                        context: context,
                        applicationName: 'BockSheets',
                        applicationVersion: '1.0.0',
                        applicationIcon: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.grid_on_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        children: [
                          const Text('A powerful spreadsheet application built with Flutter.'),
                          const SizedBox(height: 8),
                          const Text('Features:'),
                          const Text('• Create and edit spreadsheets'),
                          const Text('• Import/Export CSV and Excel'),
                          const Text('• Formula support'),
                          const Text('• Real-time collaboration'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }


  // void _handleImport() {
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('CSV/Excel import feature coming soon'),
  //       duration: Duration(seconds: 2),
  //     ),
  //   );
  // }
Future<void> _handleImport() async {
  final fileService = FileService();
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Importing CSV...'),
        ],
      ),
    ),
  );
  
  try {
    final cells = await fileService.importCSV();
    
    if (mounted) Navigator.of(context).pop();
    
    if (cells != null && cells.isNotEmpty) {
      if (!mounted) return;
      
      // Create new spreadsheet with imported data
      final provider = context.read<SpreadsheetProvider>();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final spreadsheetId = await provider.createSpreadsheet(
        title: 'Imported_$timestamp'
      );
      
      if (spreadsheetId != null && mounted) {
        // Load the spreadsheet and add cells
        await provider.loadSpreadsheet(spreadsheetId);
        cells.forEach((address, cellData) {
          provider.updateCell(address, cellData);
        });
        await provider.saveSpreadsheet();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported ${cells.length} cells successfully'),
              backgroundColor: AppTheme.success,
            ),
          );
          
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SpreadsheetScreen(
                spreadsheetId: spreadsheetId,
                title: 'Imported_$timestamp',
              ),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data imported or import cancelled'),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}

  void _duplicateSpreadsheet(Map<String, dynamic> sheet) async {
    final provider = context.read<SpreadsheetProvider>();
    final newTitle = '${sheet['title']} (Copy)';
    
    final newId = await provider.createSpreadsheet(title: newTitle);
    
    if (newId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spreadsheet duplicated successfully'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

void _showExportOptions(Map<String, dynamic> sheet) async {
  // First load the spreadsheet
  final provider = context.read<SpreadsheetProvider>();
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading spreadsheet...'),
        ],
      ),
    ),
  );
  
  final loaded = await provider.loadSpreadsheet(sheet['id']);
  
  if (!mounted) return;
  Navigator.pop(context); // Close loading dialog
  
  if (!loaded) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Failed to load spreadsheet'),
        backgroundColor: AppTheme.error,
      ),
    );
    return;
  }
  
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Export Format',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.file_download, color: AppTheme.primaryBlue),
            title: const Text('Export as CSV'),
            onTap: () async {
              Navigator.pop(context);
              await _exportSpreadsheet(sheet, 'csv');
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download, color: AppTheme.primaryViolet),
            title: const Text('Export as XLSX'),
            onTap: () async {
              Navigator.pop(context);
              await _exportSpreadsheet(sheet, 'xlsx');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

Future<void> _exportSpreadsheet(Map<String, dynamic> sheet, String format) async {
  final provider = context.read<SpreadsheetProvider>();
  final fileName = sheet['title'] ?? 'spreadsheet';
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text('Exporting...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }
  
  String? filePath;
  try {
    if (format == 'csv') {
      filePath = await provider.exportToCSV(fileName, 100, 26);
    } else {
      filePath = await provider.exportToXLSX(fileName, 100, 26);
    }
    
    if (mounted) {
      if (filePath != null && filePath.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('✓ Exported successfully!'),
                const SizedBox(height: 4),
                Text(
                  'Saved: ${filePath.split('/').last}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            duration: const Duration(seconds: 5),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export cancelled'),
            backgroundColor: AppTheme.warning,
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}

  void _showRenameDialog(Map<String, dynamic> sheet) async {
    final controller = TextEditingController(text: sheet['title']);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Spreadsheet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Spreadsheet Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final provider = context.read<SpreadsheetProvider>();
      final success = await provider.updateSpreadsheetTitle(sheet['id'], result);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spreadsheet renamed successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(String title) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Spreadsheet'),
        content: Text('Are you sure you want to delete "$title"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hr ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }


  void _showLanguageSelector(ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: themeProvider.language,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setLanguage(value);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Language changed to English')),
                  );
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Español'),
              value: 'es',
              groupValue: themeProvider.language,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setLanguage(value);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Idioma cambiado a Español')),
                  );
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Français'),
              value: 'fr',
              groupValue: themeProvider.language,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setLanguage(value);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Langue changée en Français')),
                  );
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Deutsch'),
              value: 'de',
              groupValue: themeProvider.language,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setLanguage(value);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sprache auf Deutsch geändert')),
                  );
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('हिन्दी'),
              value: 'hi',
              groupValue: themeProvider.language,
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setLanguage(value);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('भाषा हिन्दी में बदली गई')),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en': return 'English';
      case 'es': return 'Español';
      case 'fr': return 'Français';
      case 'de': return 'Deutsch';
      case 'hi': return 'हिन्दी';
      default: return 'English';
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Getting Started',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• Click "New Spreadsheet" to create a new sheet'),
              const Text('• Import CSV or Excel files using the Import button'),
              const Text('• Double-click a cell to edit its content'),
              const SizedBox(height: 16),
              const Text(
                'Formulas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• Start formulas with = sign (e.g., =SUM(A1:A5))'),
              const Text('• Supported: SUM, AVERAGE, MIN, MAX, COUNT, IF'),
              const Text('• Array formulas: ARRAYSUM, ARRAYMULTIPLY, etc.'),
              const SizedBox(height: 16),
              const Text(
                'Keyboard Shortcuts',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('• Arrow keys: Navigate cells'),
              const Text('• Enter: Move down'),
              const Text('• Tab: Move right'),
              const Text('• Delete/Backspace: Clear cell'),
              const SizedBox(height: 16),
              const Text(
                'Need More Help?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('Email: support@bocksheets.com'),
              const Text('Website: www.bocksheets.com'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}