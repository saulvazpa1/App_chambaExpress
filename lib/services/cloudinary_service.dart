
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'swciogd0';
  static const String _uploadPreset = 'chambaexpress_fotos';

  Future<String> subirFotografia(File imagen) async {
    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final solicitud = http.MultipartRequest('POST', url);

    solicitud.fields['upload_preset'] = _uploadPreset;

    solicitud.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imagen.path,
      ),
    );

    final respuesta = await solicitud.send();
    final contenido = await respuesta.stream.bytesToString();

    final datos = jsonDecode(contenido);

    if (respuesta.statusCode != 200) {
      throw Exception(
        datos['error']?['message'] ?? 'No se pudo subir la fotografía',
      );
    }

    return datos['secure_url'] as String;
  }
}
