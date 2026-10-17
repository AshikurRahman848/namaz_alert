import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:namaz_alert/core/constants/app_colors.dart';
import 'package:namaz_alert/features/group/controller/group_controller.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Dhaka');
  final _countryCtrl = TextEditingController(text: 'Bangladesh');
  int _offsetMinutes = 10;

  final GroupController _groupCtrl = Get.find();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _groupCtrl.createGroup(
        name: _nameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        offsetMinutes: _offsetMinutes,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Group')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Text('👥', style: TextStyle(fontSize: 56)),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Setup your office namaz group',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'e.g. ABC Office — Namaz Team',
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter group name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter city' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _countryCtrl,
                decoration: const InputDecoration(
                  labelText: 'Country',
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter country' : null,
              ),
              const SizedBox(height: 24),
              // Notification Offset Selector
              const Text(
                '🔔 Notify how many minutes before namaz?',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [5, 10, 15, 20, 30].map((min) {
                  final selected = _offsetMinutes == min;
                  return GestureDetector(
                    onTap: () => setState(() => _offsetMinutes = min),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: selected
                            ? null
                            : Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$min',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textDark,
                            ),
                          ),
                          Text(
                            'min',
                            style: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? Colors.white70
                                  : AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              // Info card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'An invite code will be generated. Share it with your team to join.',
                        style: TextStyle(
                            color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Obx(() => ElevatedButton(
                    onPressed:
                        _groupCtrl.isLoading.value ? null : _submit,
                    child: _groupCtrl.isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Create Group',
                            style: TextStyle(fontSize: 16)),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
