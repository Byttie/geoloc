import 'dart:io';
import 'package:flutter/material.dart';
import '../model/entity.dart';
import '../modelView/location_service.dart';
import '../modelView/entity_manager.dart';
import '../modelView/image_manager.dart';


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
      // Silently handle location errors
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
        setState(() {
          _imageFile = imageFile;
        });
      }
    } catch (e) {
      // Silently handle image picking errors
    }
  }

  Future<void> _takePhoto() async {
    try {
      final imageFile = await _imageManager.takePhoto();
      if (imageFile != null) {
        setState(() {
          _imageFile = imageFile;
        });
      }
    } catch (e) {
      // Silently handle camera errors
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
          imageFile: null,
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
          if (!_isEdit && _imageFile != null) {
            _imageManager.cleanupTempFiles(_imageFile);
            _imageFile = null;
          }
          
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      // Silently handle submission errors
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
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                ),
              ),
            SizedBox(height: 8),
            if (!_isEdit)
              ElevatedButton(
                onPressed: _showImageSourceDialog,
                child: Text('Add Image'),
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
    if (_imageFile != null) {
      _imageManager.cleanupTempFiles(_imageFile);
    }
    
    _titleController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }
} 