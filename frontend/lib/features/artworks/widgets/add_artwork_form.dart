import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/artwork_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import '../models/category_model.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddArtworkForm extends StatefulWidget {
  final double latitude;
  final double longitude;

  const AddArtworkForm({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  State<AddArtworkForm> createState() => _AddArtworkFormState();
}

class _AddArtworkFormState extends State<AddArtworkForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  XFile? _imageFile;
  bool _isLoading = false;
  bool _imageUploading = false;
  List<ArtworkCategory> _categories = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final artworkProvider = context.read<ArtworkProvider>();
      final categories = await artworkProvider.getCategories();
      print('Loaded categories: $categories');
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = image;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add New Artwork',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _imageUploading ? null : _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _imageUploading
                      ? const Center(child: CircularProgressIndicator())
                      : _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildImagePreview(),
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 48),
                                  Text('Tap to add image'),
                                ],
                              ),
                            ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdown(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add Artwork'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_imageFile == null) {
      return const Center(
        child: Text('No image selected'),
      );
    }

    if (kIsWeb) {
      return Image.network(_imageFile!.path);
    } else {
      return Image.file(File(_imageFile!.path));
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate() && _imageFile != null) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        late final MultipartFile imageFile;
        if (kIsWeb) {
          final bytes = await _imageFile!.readAsBytes();
          imageFile = MultipartFile.fromBytes(
            bytes,
            filename: _imageFile!.name,
          );
        } else {
          imageFile = await MultipartFile.fromFile(
            _imageFile!.path,
            filename: _imageFile!.name,
          );
        }

        final formData = FormData();
        formData.fields.addAll([
          MapEntry('title', _titleController.text),
          MapEntry('description', _descriptionController.text),
          MapEntry('latitude', widget.latitude.toString()),
          MapEntry('longitude', widget.longitude.toString()),
          MapEntry('category_id', _selectedCategory ?? ''),
        ]);

        formData.files.add(MapEntry('image', imageFile));

        await context.read<ArtworkProvider>().addArtwork(
          formData,
          context.read<AuthProvider>().user?.username ?? 'Unknown Artist',
        );

        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        print('Error submitting form: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating artwork: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and select an image')),
      );
    }
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Select a category'),
      value: _selectedCategory,
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category.name,
          child: Text(category.name),
        );
      }).toList(),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a category';
        }
        return null;
      },
      onChanged: (String? value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 