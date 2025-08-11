import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../model/entity.dart';
import '../modelView/location_service.dart';
import '../modelView/entity_manager.dart';
import '../modelView/image_manager.dart';

// Custom memory-efficient image widget
class MemoryEfficientImage extends StatefulWidget {
  final File imageFile;
  final double height;
  final BoxFit fit;

  const MemoryEfficientImage({
    super.key,
    required this.imageFile,
    this.height = 200,
    this.fit = BoxFit.cover,
  });

  @override
  State<MemoryEfficientImage> createState() => _MemoryEfficientImageState();
}

class _MemoryEfficientImageState extends State<MemoryEfficientImage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImageBytes();
  }

  Future<void> _loadImageBytes() async {
    try {
      if (await widget.imageFile.exists()) {
        final bytes = await widget.imageFile.readAsBytes();
        if (mounted) {
          setState(() {
            _imageBytes = bytes;
            _isLoading = false;
            _hasError = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _imageBytes = null; // Release memory
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Loading...', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              )
            : _hasError || _imageBytes == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 50, color: Colors.grey[600]),
                      Text('Failed to load image', style: TextStyle(color: Colors.grey[600])),
                    ],
                  )
                : Image.memory(
                    _imageBytes!,
                    fit: widget.fit,
                    cacheWidth: 200, // Minimal cache
                    cacheHeight: 150,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 50, color: Colors.grey[600]),
                        Text('Error displaying image', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class EntityForm extends StatefulWidget {
  final Entity? entity;

  const EntityForm({super.key, this.entity});

  @override
  State<EntityForm> createState() => _EntityFormState();
}

class _EntityFormState extends State<EntityForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  
  final EntityManager _entityManager = EntityManager();
  final LocationService _locationService = LocationService();
  final ImageManager _imageManager = ImageManager();
  
  File? _imageFile;
  File? _previousImageFile; // Keep track for cleanup
  bool _isLoading = false;
  bool _isEdit = false;

  @override
  void initState() {
    super.initState();
    _isEdit = widget.entity != null;
    
    if (_isEdit) {
      _titleController.text = widget.entity!.title;
      _latController.text = widget.entity!.lat.toString();
      _lonController.text = widget.entity!.lon.toString();
    } else {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        setState(() {
          _latController.text = position.latitude.toString();
          _lonController.text = position.longitude.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final imageFile = await _imageManager.pickImageFromGallery();
      if (imageFile != null) {
        // Clean up previous image file
        if (_previousImageFile != null) {
          await _imageManager.cleanupTempFiles(_previousImageFile);
        }
        
        setState(() {
          _previousImageFile = _imageFile;
          _imageFile = imageFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final imageFile = await _imageManager.takePhoto();
      if (imageFile != null) {
        // Clean up previous image file
        if (_previousImageFile != null) {
          await _imageManager.cleanupTempFiles(_previousImageFile);
        }
        
        setState(() {
          _previousImageFile = _imageFile;
          _imageFile = imageFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              title: Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final title = _titleController.text.trim();
      final lat = double.parse(_latController.text);
      final lon = double.parse(_lonController.text);

      bool success;
      if (_isEdit) {
        success = await _entityManager.updateEntity(
          id: widget.entity!.id!,
          title: title,
          lat: lat,
          lon: lon,
          imageFile: _imageFile,
          currentImage: widget.entity!.image,
        );
      } else {
        success = await _entityManager.createEntity(
          title: title,
          lat: lat,
          lon: lon,
          imageFile: _imageFile,
        );
      }

      if (mounted) {
        if (success) {
          // Clean up image files after successful submission
          if (_imageFile != null) {
            _imageManager.cleanupTempFiles(_imageFile);
            _imageFile = null;
          }
          if (_previousImageFile != null) {
            _imageManager.cleanupTempFiles(_previousImageFile);
            _previousImageFile = null;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEdit ? 'Entity updated successfully' : 'Entity created successfully')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEdit ? 'Failed to update entity' : 'Failed to create entity')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit' : 'Create')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    decoration: InputDecoration(labelText: 'Latitude'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _lonController,
                    decoration: InputDecoration(labelText: 'Longitude'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid number';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _getCurrentLocation,
              child: Text('Use Current Location'),
            ),
            SizedBox(height: 16),
            if (_imageFile != null)
              MemoryEfficientImage(imageFile: _imageFile!)
            else if (_isEdit && widget.entity!.image != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.entity!.getFullImageUrl()!,
                    fit: BoxFit.cover,
                    cacheWidth: 150, // Minimal cache
                    cacheHeight: 113,
                    errorBuilder: (context, error, stackTrace) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 50, color: Colors.grey[600]),
                        Text('Failed to load image', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('Loading image...', style: TextStyle(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showImageSourceDialog,
              child: Text(_imageFile != null || (_isEdit && widget.entity!.image != null)
                  ? 'Change Image'
                  : 'Add Image'),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text(_isEdit ? 'Update Entity' : 'Create Entity'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up image files
    if (_imageFile != null) {
      _imageManager.cleanupTempFiles(_imageFile);
    }
    if (_previousImageFile != null) {
      _imageManager.cleanupTempFiles(_previousImageFile);
    }
    
    _titleController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }
} 