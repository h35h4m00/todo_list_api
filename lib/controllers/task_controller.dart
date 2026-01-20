import 'package:get/get.dart';
import '../models/task.dart';
import '../services/api/dio_client.dart';

class TaskController extends GetxController {
  final DioClient _dioClient = DioClient();

  final RxList<Task> _tasks = <Task>[].obs;

  String? selectedCategoryId;

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  List<Task> get tasks => _tasks.toList();

  Future<void> fetchTasks() async {
    try {
      final response =
          await _dioClient.get('/todos', queryParameters: {'limit': 20});

      if (response.statusCode == 200) {
        final List<dynamic> todosJson = response.data['todos'];

        _tasks.value = todosJson.map((json) {
          return Task(
            id: json['id'].toString(),
            title: json['todo'],
            description: '',
            categoryId: null,
            isCompleted: json['completed'],
            createdAt: DateTime.now(),
          );
        }).toList();
      }
    } catch (e) {
      print("Error fetching tasks: $e");
    }
  }

  List<Task> get filteredTasks {
    if (selectedCategoryId == null) {
      return tasks;
    }
    return tasks.where((t) => t.categoryId == selectedCategoryId).toList();
  }

  List<Task> get completedTasks =>
      filteredTasks.where((t) => t.isCompleted).toList();
  List<Task> get pendingTasks =>
      filteredTasks.where((t) => !t.isCompleted).toList();

  Future<void> addTask(Task task) async {
    try {
      await _dioClient.post('/todos/add', data: {
        'todo': task.title,
        'completed': task.isCompleted,
        'userId': 5,
      });

      await fetchTasks();
      update();
      Get.snackbar('Success', 'Task added',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print("Error adding task: $e");
      Get.snackbar('Error', 'Failed to add task',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _dioClient.put('/todos/${task.id}', data: {
        'todo': task.title,
        'completed': task.isCompleted,
      });

      await fetchTasks();
      update();
      Get.snackbar('Success', 'Task updated',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print("Error updating task: $e");
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _dioClient.delete('/todos/$id');

      await fetchTasks();
      update();
      Get.snackbar('Success', 'Task deleted',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      print("Error deleting task: $e");
    }
  }

  Future<void> toggleComplete(String id) async {
    final task = tasks.firstWhereOrNull((t) => t.id == id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      await updateTask(task);
    }
  }

  void setFilter(String? categoryId) {
    selectedCategoryId = categoryId;
    update();
  }

  Task? getTask(String id) => tasks.firstWhereOrNull((t) => t.id == id);
}
