import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/artwork_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';

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
  String? _selectedCategory;
  bool _imageUploading = false;
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final artworkProvider = context.read<ArtworkProvider>();
      final categories = await artworkProvider.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
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
              if (_categories.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  hint: const Text('Select a category'),
                  items: _categories.map((String category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                ),
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
      setState(() {
        _isLoading = true;
      });
      
      try {
        FormData formData;
        if (kIsWeb) {
          // For web platform
          List<int> bytes = await _imageFile!.readAsBytes();
          formData = FormData.fromMap({
            'title': _titleController.text,
            'description': _descriptionController.text,
            'latitude': widget.latitude,
            'longitude': widget.longitude,
            'category': _selectedCategory,
            'image': MultipartFile.fromBytes(
              bytes,
              filename: _imageFile!.name,
            ),
          });
        } else {
          // For mobile platforms
          formData = FormData.fromMap({
            'title': _titleController.text,
            'description': _descriptionController.text,
            'latitude': widget.latitude,
            'longitude': widget.longitude,
            'category': _selectedCategory,
            'image': await MultipartFile.fromFile(_imageFile!.path),
          });
        }

        // Submit using your artwork service
        await context.read<ArtworkProvider>().addArtwork(formData);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Artwork added successfully!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        print('Error in _submitForm: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading artwork: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields and select an image')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
} 