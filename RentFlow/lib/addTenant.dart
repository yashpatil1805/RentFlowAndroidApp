import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AddTenantScreen extends StatefulWidget {
  const AddTenantScreen({Key? key}) : super(key: key);

  @override
  State<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  final TextEditingController flatIdController = TextEditingController();
  final TextEditingController rentController = TextEditingController();
  final TextEditingController waterBillController = TextEditingController();
  final TextEditingController depositController = TextEditingController();

  // List to hold persons information (name, phone, address)
  List<Map<String, String>> persons = [];

  // Controllers for multiple persons
  final List<TextEditingController> nameControllers = [];
  final List<TextEditingController> phoneControllers = [];
  final List<TextEditingController> addressControllers = [];

  // Add a new person input field
  void addPersonField() {
    setState(() {
      nameControllers.add(TextEditingController());
      phoneControllers.add(TextEditingController());
      addressControllers.add(TextEditingController());
      persons.add({'name': '', 'phone': '', 'address': ''});
    });
  }

  // Remove a person input field
  void removePersonField(int index) {
    setState(() {
      nameControllers.removeAt(index);
      phoneControllers.removeAt(index);
      addressControllers.removeAt(index);
      persons.removeAt(index);
    });
  }

  Future<void> addTenantToFirestore() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Prepare person details
        List<Map<String, dynamic>> personsList = [];
        for (int i = 0; i < persons.length; i++) {
          personsList.add({
            'name': nameControllers[i].text,
            'phone': phoneControllers[i].text,
            'address': addressControllers[i].text,
          });
        }

        // Save to Firestore
        await FirebaseFirestore.instance.collection('tenants').add({
          'flatId': flatIdController.text,
          'rent': double.parse(rentController.text),
          'waterBill': double.parse(waterBillController.text),
          'deposit': double.parse(depositController.text),
          'persons': personsList, // Store persons as a list of maps
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tenant added successfully!')),
        );

        // Clear the fields
        flatIdController.clear();
        rentController.clear();
        waterBillController.clear();
        depositController.clear();
        persons.clear();
        nameControllers.clear();
        phoneControllers.clear();
        addressControllers.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add tenant: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  AppBar(
        title: Text('Add Tenant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: flatIdController,
                decoration: const InputDecoration(labelText: 'Flat ID'),
                validator: (value) => value!.isEmpty ? 'Flat ID is required' : null,
              ),
              TextFormField(
                controller: rentController,
                decoration: const InputDecoration(labelText: 'Rent'),
                validator: (value) => value!.isEmpty ? 'Rent is required' : null,
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: waterBillController,
                decoration: const InputDecoration(labelText: 'Water Bill'),
                validator: (value) => value!.isEmpty ? 'Water Bill is required' : null,
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: depositController,
                decoration: const InputDecoration(labelText: 'Deposit'),
                validator: (value) => value!.isEmpty ? 'Deposit is required' : null,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),

              // Dynamic form fields for multiple persons
              const Text('Add Persons'),
              ListView.builder(
                shrinkWrap: true,
                itemCount: persons.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: nameControllers[index],
                            decoration: const InputDecoration(labelText: 'Name'),
                            validator: (value) =>
                            value!.isEmpty ? 'Name is required' : null,
                          ),
                          TextFormField(
                            controller: phoneControllers[index],
                            decoration: const InputDecoration(labelText: 'Phone'),
                            validator: (value) =>
                            value!.isEmpty ? 'Phone is required' : null,
                            keyboardType: TextInputType.phone,
                          ),
                          TextFormField(
                            controller: addressControllers[index],
                            decoration: const InputDecoration(labelText: 'Address'),
                            validator: (value) =>
                            value!.isEmpty ? 'Address is required' : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: () => removePersonField(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              ElevatedButton(
                onPressed: addPersonField,
                child: const Text('Add Person'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: addTenantToFirestore,
                child: const Text('Add Tenant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
