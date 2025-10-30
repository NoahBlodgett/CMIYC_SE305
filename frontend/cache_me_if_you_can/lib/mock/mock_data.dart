// Mock data and service stubs for frontend development and testing.
// Use these functions to simulate network calls until the backend is available.

import 'dart:async';

final Map<String, dynamic> mockUserProfile = {
  "userId": "U12345",
  "name": "Alex Carter",
  "email": "alex.carter@example.com",
  // password stored as placeholder — DO NOT use real passwords
  "password": "hashedPassword!",
  "age": 28,
  "height_cm": 178,
  "weight_kg": 74,
  "goal": "build muscle",
  "activityLevel": "moderate",
  "allergies": ["peanuts"],
  "preferences": ["high protein", "low sugar"],
  "dateJoined": "2025-10-01",
};

final List<Map<String, dynamic>> mockWorkoutLogs = [
  {
    "logId": "W001",
    "userId": "U12345",
    "date": "2025-10-20",
    "workoutName": "Leg Day",
    "exerciseList": [
      {"exercise": "Squat", "sets": 3, "reps": 10, "weight": 185},
      {"exercise": "Lunge", "sets": 2, "reps": 12, "weight": 65},
    ],
    "totalCaloriesBurned": 450,
    "duration_min": 60,
  },
  {
    "logId": "W002",
    "userId": "U12345",
    "date": "2025-10-22",
    "workoutName": "Upper Body",
    "exerciseList": [
      {"exercise": "Bench Press", "sets": 3, "reps": 8, "weight": 155},
      {"exercise": "Pull Up", "sets": 3, "reps": 6, "weight": 0},
    ],
    "totalCaloriesBurned": 380,
    "duration_min": 50,
  },
];

final List<Map<String, dynamic>> mockNutritionLogs = [
  {
    "mealId": "N023",
    "userId": "U12345",
    "date": "2025-10-20",
    "mealType": "Dinner",
    "items": [
      {
        "food": "Grilled Chicken",
        "calories": 200,
        "protein": 38,
        "carbs": 0,
        "fat": 4,
      },
      {
        "food": "Brown Rice",
        "calories": 220,
        "protein": 5,
        "carbs": 45,
        "fat": 2,
      },
    ],
    "totalCalories": 420,
    "targetCalories": 2500,
  },
  {
    "mealId": "N024",
    "userId": "U12345",
    "date": "2025-10-21",
    "mealType": "Breakfast",
    "items": [
      {
        "food": "Oatmeal",
        "calories": 320,
        "protein": 10,
        "carbs": 50,
        "fat": 6,
      },
    ],
    "totalCalories": 320,
    "targetCalories": 2500,
  },
];

final Map<String, dynamic> mockGamification = {
  "userId": "U12345",
  "streakDays": 7,
  "badgesEarned": ["First Workout", "7-Day Streak", "Protein Tracker"],
  "level": 3,
  "experiencePoints": 1450,
  "milestones": [
    {"goal": "10 workouts completed", "status": "in progress"},
    {"goal": "Reach 100 total miles", "status": "complete"},
  ],
};

final Map<String, dynamic> mockRecommendations = {
  "userId": "U12345",
  "recommendedWorkouts": [
    {"name": "Upper Body Strength", "focus": "arms", "duration": 45},
  ],
  "recommendedMeals": [
    {"meal": "Oatmeal with almonds", "calories": 400, "protein": 15},
  ],
  "nextGoal": "Increase weekly workout frequency to 4",
};

// --- Service stubs ----------------------------------------------------

const Duration _mockNetworkDelay = Duration(milliseconds: 400);

// Programs mock ---------------------------------------------------------

final List<String> mockPrograms = <String>[
  'Beginner Full Body (Week 3)',
  'Push/Pull/Legs Split',
  '5K Training Plan',
  'Upper/Lower Strength',
];

String mockCurrentProgramName = mockPrograms.first;

Future<String> fetchCurrentProgramName() async {
  await Future.delayed(_mockNetworkDelay);
  return mockCurrentProgramName;
}

Future<List<String>> fetchRecentPrograms({int limit = 10}) async {
  await Future.delayed(_mockNetworkDelay);
  return List<String>.from(mockPrograms.take(limit));
}

Future<void> setCurrentProgramName(String name) async {
  await Future.delayed(_mockNetworkDelay);
  mockCurrentProgramName = name;
  if (!mockPrograms.contains(name)) {
    mockPrograms.insert(0, name);
  }
}

Future<Map<String, dynamic>> mockLogin(String email, String password) async {
  // Simulate checking credentials; password is not validated in this mock.
  await Future.delayed(_mockNetworkDelay);
  if (email == mockUserProfile['email']) {
    return {
      'ok': true,
      'user': mockUserProfile,
      // return a mock token if desired
      'token': 'mock-token-123',
    };
  }
  return {'ok': false, 'error': 'Invalid credentials'};
}

Future<Map<String, dynamic>> fetchUserProfile() async {
  await Future.delayed(_mockNetworkDelay);
  return Map<String, dynamic>.from(mockUserProfile);
}

Future<List<Map<String, dynamic>>> fetchWorkoutLogs({int limit = 20}) async {
  await Future.delayed(_mockNetworkDelay);
  return List<Map<String, dynamic>>.from(mockWorkoutLogs);
}

Future<List<Map<String, dynamic>>> fetchNutritionLogs({int limit = 20}) async {
  await Future.delayed(_mockNetworkDelay);
  return List<Map<String, dynamic>>.from(mockNutritionLogs);
}

Future<Map<String, dynamic>> fetchGamification() async {
  await Future.delayed(_mockNetworkDelay);
  return Map<String, dynamic>.from(mockGamification);
}

Future<Map<String, dynamic>> fetchRecommendations() async {
  await Future.delayed(_mockNetworkDelay);
  return Map<String, dynamic>.from(mockRecommendations);
}

// Utility: update local mock profile (simulates saving to server).
Future<void> saveUserProfile(Map<String, dynamic> updated) async {
  await Future.delayed(_mockNetworkDelay);
  // merge keys into mockUserProfile (in-memory only)
  updated.forEach((k, v) => mockUserProfile[k] = v);
}

// Save a new nutrition or workout entry locally (append)
Future<void> addWorkoutLog(Map<String, dynamic> log) async {
  await Future.delayed(_mockNetworkDelay);
  mockWorkoutLogs.insert(0, log);
}

Future<void> addNutritionLog(Map<String, dynamic> meal) async {
  await Future.delayed(_mockNetworkDelay);
  mockNutritionLogs.insert(0, meal);
}

// Clear mocks (useful in tests)
void resetMocks() {
  // Intentionally simplistic: not restoring an original snapshot.
}

// End of mock_data.dart
