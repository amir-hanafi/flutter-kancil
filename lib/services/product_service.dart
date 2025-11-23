// import 'dart:io';

// Future<bool> uploadProduct({
//   required String name,
//   required String description,
//   required String price,
//   required File imageFile,
// }) async {

//   final request = http.MultipartRequest('POST', uri)
//     ..fields['name'] = name
//     ..fields['description'] = description
//     ..fields['price'] = price
//     ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

//   final response = await request.send();

//   return response.statusCode == 201;
// }
