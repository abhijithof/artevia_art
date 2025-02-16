import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.user;
        
        if (user == null) {
          return const Center(child: Text('Please log in'));
        }

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Profile Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            user.username[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.username,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.email,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Artist Badge
                              if (user.role == 'artist')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.palette, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Artist',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    // Become Artist Button - Only show if not already an artist
                    if (user.role != 'artist')
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await authProvider.convertToArtist();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Successfully became an artist!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Become an Artist'),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          authProvider.logout();
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 