import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'addTenant.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tenants App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenants List'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tenants').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No tenants found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final tenant = snapshot.data!.docs[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(tenant['flatId'].toString()),
                  subtitle: Text('Rent: ${tenant['rent']}                                                                     Deposit: ${tenant['deposit']}'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TenantDetailsScreen(tenant: tenant),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTenantScreen()),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Tenant',
      ),
    );
  }
}

class TenantDetailsScreen extends StatelessWidget {
  final QueryDocumentSnapshot tenant;

  const TenantDetailsScreen({Key? key, required this.tenant}) : super(key: key);

  Future<void> _generatePDFAndShare(Map<String, dynamic> invoiceData) async {
    final pdf = pw.Document();

    String total = invoiceData['Total'].toString(); // Retrieve total dynamically
    String upiLink = 'upi://pay?pa=prajaktalpatil1104@okhdfcbank'
        '&pn=${Uri.encodeComponent("Prajakta Patil")}'
        '&am=$total&cu=INR'; // Use total here

    final qrImage = await QrPainter(
      data: upiLink,
      version: QrVersions.auto,
      gapless: false,
    ).toImage(200);

    final qrImageBytes = await qrImage.toByteData(format: ImageByteFormat.png);
    final qrImageList = qrImageBytes!.buffer.asUint8List();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Container(
          padding: pw.EdgeInsets.all(16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Invoice Details",
                style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Flat ID:", style: pw.TextStyle(fontSize: 18)),
                  pw.Text(invoiceData['flatId'].toString(), style: pw.TextStyle(fontSize: 18)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.SizedBox(height: 20),
              pw.Text("Charges:", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Rent:", style: pw.TextStyle(fontSize: 18)),
                  pw.Text("${invoiceData['Rent']}", style: pw.TextStyle(fontSize: 18)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Water Bill:", style: pw.TextStyle(fontSize: 18)),
                  pw.Text("${invoiceData['WaterBill']}", style: pw.TextStyle(fontSize: 18)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Previous Units:", style: pw.TextStyle(fontSize: 18)),
                  pw.Text("${invoiceData['PreviousUnits']}", style: pw.TextStyle(fontSize: 18)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Current Units:", style: pw.TextStyle(fontSize: 18)),
                  pw.Text("${invoiceData['CurrentUnits']}", style: pw.TextStyle(fontSize: 18)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Electricity Bill:", style: pw.TextStyle(fontSize: 18)),
                  pw.Text("${invoiceData['ElectricityBill']}", style: pw.TextStyle(fontSize: 18)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                "Total Amount: ${invoiceData['Total']}",
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),

              pw.SizedBox(height: 20),
              pw.Text(
                "Date: ${invoiceData['Date']} \nEnsure the rent is paid before the 5th of each month. No delays will be accepted.",
                style: pw.TextStyle(fontSize: 16, fontStyle: pw.FontStyle.italic),
              ),

              pw.SizedBox(height: 20),

              pw.Text(
                "Pay via UPI: ",
                style: pw.TextStyle(fontSize: 18),
              ),
              pw.Image(pw.MemoryImage(qrImageList)),
              pw.SizedBox(height: 20),
              pw.Text(
                "OR Pay using below UPI number (GPay, Paytm, PhonePe) => 8698203878 (Prajakta Patil)",
                style: pw.TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/invoice.pdf");
    await file.writeAsBytes(await pdf.save());
    String text = "Here is the invoice for your recent charges. Please find the details in the attached PDF.";

    await Share.shareXFiles([XFile(file.path)], text: text);
  }

  void _generateInvoice(BuildContext context) async {
    final currentUnitsController = TextEditingController();
    final previousUnitsController = TextEditingController();

    try {
      final lastInvoiceSnapshot = await FirebaseFirestore.instance
          .collection('invoices')
          .where('flatId', isEqualTo: tenant['flatId'])
          .orderBy('CurrentUnits', descending: true)
          .limit(1)
          .get();

      bool isFirstInvoice = lastInvoiceSnapshot.docs.isEmpty;

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Generate Invoice'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFirstInvoice)
                  TextField(
                    controller: previousUnitsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Enter Previous Units'),
                  ),
                TextField(
                  controller: currentUnitsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Enter Current Units'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final currentUnits = int.tryParse(currentUnitsController.text);
                  final previousUnits = isFirstInvoice
                      ? int.tryParse(previousUnitsController.text)
                      : lastInvoiceSnapshot.docs.first['CurrentUnits'];

                  if (currentUnits == null ||
                      previousUnits == null ||
                      currentUnits <= previousUnits) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invalid units value')),
                    );
                    return;
                  }

                  final rent = tenant['rent'];
                  final waterBill = tenant['waterBill'];
                  final electricityBill = (currentUnits - previousUnits) * 10;
                  final total = rent + waterBill + electricityBill;
                  final date = DateTime.now();
                  final formattedDate =
                      '${date.day}/${date.month}/${date.year}';

                  await FirebaseFirestore.instance.collection('invoices').add({
                    'flatId': tenant['flatId'],
                    'Phone': tenant['persons'][0]['phone'], // Correctly accessing phone
                    'Rent': rent,
                    'WaterBill': waterBill,
                    'PreviousUnits': previousUnits,
                    'CurrentUnits': currentUnits,
                    'ElectricityBill': electricityBill,
                    'Date': formattedDate,
                    'Month': date.month,
                    'Total': total,
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invoice generated successfully!')),
                  );
                  Navigator.pop(context);
                },
                child: Text('Generate'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error while fetching invoices: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching previous invoices: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final persons = tenant['persons'] as List;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tenant Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Phone')),
                DataColumn(label: Text('Address')),
              ],
              rows: persons.map((person) {
                return DataRow(cells: [
                  DataCell(Text(person['name'])),
                  DataCell(Text(person['phone'])),
                  DataCell(Text(person['address'])),
                ]);
              }).toList(),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _generateInvoice(context),
            child: Text('Generate Invoice'),
          ),
          SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('invoices')
                  .where('flatId', isEqualTo: tenant['flatId'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No invoices found.'));
                }

                return DataTable(
                    columnSpacing: 10.0,
                  columns: const [
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Month')),
                    DataColumn(label: Text('PUnits')),
                    DataColumn(label: Text('CUnits')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Action')),
                  ],
                  rows: snapshot.data!.docs.map((doc) {
                    return DataRow(cells: [
                      DataCell(Text(doc['Date'])),
                      DataCell(Text(doc['Month'].toString())),
                      DataCell(Text(doc['PreviousUnits'].toString())),
                      DataCell(Text(doc['CurrentUnits'].toString())),
                      DataCell(Text(doc['Total'].toString())),
                      DataCell(
                        IconButton(
                          icon: Icon(Icons.share),
                          onPressed: () => _generatePDFAndShare(doc.data() as Map<String, dynamic>),
                        ),
                      ),
                    ]);
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
