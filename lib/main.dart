import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Map<String, dynamic>> dataRows = [];
  String errorMessage = ''; // Error message to display

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users Salaries Upload & View'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                // Open a file picker to select an Excel file
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['xlsx'],
                );
                if (result != null) {
                  final bytes = result.files.first.bytes;
                  final excel = Excel.decodeBytes(bytes!);

                  // Assuming the first sheet is named 'Sheet1'
                  final table = excel.tables['Sheet1'];

                  if (table != null) {
                    // Initialize dataRows
                    dataRows = [];

                    // Loop through all rows and extract data
                    for (var row in table.rows.skip(1)) {
                      final rowData = {
                        'name': row[0]?.value?.toString() ?? '', // Name column
                        'salary':
                            row[2]?.value?.toString() ?? '', // Salary column
                        'percentage': row[1]?.value?.toString() ??
                            '', // Percentage column
                      };
                      dataRows.add(rowData);
                    }

                    setState(() {
                      // Update the UI to display the DataTable
                    });
                    final response = await http.post(
                      Uri.parse('http://localhost:8000/bulk-upload/'),
                      headers: <String, String>{
                        'Content-Type': 'application/json',
                      },
                      body: jsonEncode(dataRows), // Convert dataRows to JSON
                    );

                    if (response.statusCode == 201) {
                      // Successful upload, you can handle the response as needed
                      print('Bulk upload successful!');
                      setState(() {
                        errorMessage = ''; // Clear error message
                      });
                    } else if (response.statusCode == 400) {
                      // Invalid data format, display an error message
                      setState(() {
                        errorMessage =
                            'Invalid data format please add data in form of: Name: String, Salary: Float, Percentage: Float';
                      });
                    } else {
                      // Handle errors if necessary
                      print(
                          'Bulk upload failed with status code: ${response.statusCode}');
                    }
                  }
                }
              },
              child: Text('Upload your Excel File'),
            ),
            // Display an error message if there is one
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

            // Display the DataTable here
            if (dataRows.isNotEmpty)
              DataTable(
                columns: [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Percentage')),
                  DataColumn(label: Text('Salary')),
                ],
                rows: dataRows.map((rowData) {
                  return DataRow(
                    cells: [
                      DataCell(
                        GestureDetector(
                          onTap: () {
                            _showDetailedDataDialog(rowData);
                          },
                          child: Text(rowData['name']),
                        ),
                      ),
                      DataCell(Text(rowData['salary'])),
                      DataCell(Text(rowData['percentage'])),
                    ],
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // Create a function to display the user's salary information
  void _showDetailedDataDialog(Map<String, dynamic> rowData) {
    final salary = double.tryParse(rowData['salary']) ?? 0.0;
    final percentage = double.tryParse(rowData['percentage']) ?? 0.0;
    final calculatedValue = salary * percentage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: IntrinsicHeight(
            child: Container(
              width: 300.0, // Set the dialog width
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'User Information for: ' + rowData['name'],
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Salary')),
                        DataColumn(label: Text('Salary Percentage')),
                      ],
                      rows: [
                        DataRow(
                          cells: [
                            DataCell(Text('\$${salary.toStringAsFixed(2)}')),
                            DataCell(Text(
                                '\$${calculatedValue.toStringAsFixed(2)}')),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
