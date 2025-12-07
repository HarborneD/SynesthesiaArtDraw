import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/canvas_model.dart';

class CanvasRepository {
  static const String _storageKey = 'saved_canvases';

  Future<void> saveCanvas(CanvasModel canvas) async {
    final prefs = await SharedPreferences.getInstance();
    final List<CanvasModel> currentList = await getAllCanvases();

    // Check if exists and update, else add
    final index = currentList.indexWhere((c) => c.id == canvas.id);
    if (index >= 0) {
      currentList[index] = canvas;
    } else {
      currentList.add(canvas);
    }

    final String encoded = jsonEncode(
      currentList.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  Future<List<CanvasModel>> getAllCanvases() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString == null) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.map((e) => CanvasModel.fromJson(e)).toList();
    } catch (e) {
      // Handle error or return empty
      return [];
    }
  }

  Future<void> deleteCanvas(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<CanvasModel> currentList = await getAllCanvases();
    currentList.removeWhere((c) => c.id == id);

    final String encoded = jsonEncode(
      currentList.map((e) => e.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }
}
