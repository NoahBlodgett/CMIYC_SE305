const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');
const axios = require('axios');

const ML_SERVICE_URL = process.env.ML_SERVICE_URL || "http://localhost:8000";

async function createWeekPlan(req, res){
    try{
        const { userID } = req.params;  // Get userID from URL params instead of body

        // Validate required fields
        if (!userID)
        {
            return res.status(400).json({
                error: 'Missing required fields: userID'
            });
        }

        const db = getFirestore();

        // Check if user exists
        const userDoc = await db.collection('users').doc(userID).get(); 

        if (!userDoc.exists)
        {
            return res.status(404).json({
                error: 'User does not exist'
            });
        }

        let userData = userDoc.data();
        
        // Debug: Log the raw user data
        console.log('Raw user data from Firestore:', JSON.stringify(userData, null, 2));

        // Find weight goal by userID
        const goalQuery = await db.collection('weight_goals')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (goalQuery.empty) {
            // Create a default weight goal document for this user
            await db.collection('weight_goals').add({
                user_id: userID,
                weight_objective: "MAINTAIN_WEIGHT" // or "LOSE_WEIGHT" / "GAIN_WEIGHT"
            });
            // Re-run the query to get the new goal
            const newGoalQuery = await db.collection('weight_goals')
                .where('user_id', '==', userID)
                .limit(1)
                .get();
            if (newGoalQuery.empty) {
                return res.status(404).json({
                    error: 'Failed to create weight goal for this user'
                });
            }
            goalDoc = newGoalQuery.docs[0];
            goalData = goalDoc.data();
        } else {
            // Get the goal data
            var goalDoc = goalQuery.docs[0];
            var goalData = goalDoc.data();
        }

        let goal = 0;

        switch (goalData.weight_objective) {
            case "LOSE_WEIGHT":
                goal = -1;
                break;
            case "MAINTAIN_WEIGHT":
                goal = 0;
                break;
            case "GAIN_WEIGHT":
                goal = 1;
                break;
            default:
                goal = 0;
                break;
        }
        
        // Create the transformation after getting userData and goalData
        // Convert height from cm to inches (1 inch = 2.54 cm)
        const heightInInches = userData.height_cm ? userData.height_cm / 2.54 : null;
        // Weight conversion: check units_metric flag
        // If units_metric is false, weight is already in pounds
        // If units_metric is true, convert from kg to pounds
        const weightInPounds = userData.units_metric === false 
            ? userData.weight 
            : (userData.weight ? userData.weight * 2.20462 : null);
        
        // Map activity level multiplier to category (0-4)
        // Multipliers: 1.2 (sedentary), 1.375 (light), 1.55 (moderate), 1.725 (active), 1.9 (very active)
        // Categories: 0 (sedentary), 1 (light), 2 (moderate), 3 (active), 4 (very active)
        let activityCategory = 2; // default to moderate
        if (userData.activity_level <= 1.2) {
            activityCategory = 0;
        } else if (userData.activity_level <= 1.375) {
            activityCategory = 1;
        } else if (userData.activity_level <= 1.55) {
            activityCategory = 2;
        } else if (userData.activity_level <= 1.725) {
            activityCategory = 3;
        } else {
            activityCategory = 4;
        }
        
        const transformedUserData = {
            Height_in: heightInInches,
            Weight_lb: weightInPounds,
            Age: userData.age,
            Gender: userData.gender === "male" ? 1 : 0,  // Convert string to number
            Activity_Level: activityCategory,  // Use category instead of multiplier
            Goal: goal,
            allergies: Array.isArray(userData.allergies) ? userData.allergies : [],  // Handle string or array
            preferences: userData.preferences || []  // Default empty array if missing
        };
        
        // Debug: Log the transformed data being sent to ML service
        console.log('Transformed data for ML service:', JSON.stringify(transformedUserData, null, 2));

        const response = await axios.post(`${ML_SERVICE_URL}/nutrition/generate`, transformedUserData);
        
        // Debug: Log successful response
        console.log('ML service response received successfully');

        /*
        DATA RETURNED
            return sanitize_for_json({
                "success": True,
                "nutrition_targets": nutrition_targets,
                "week_plan": week_plan,
                "ingredient_counts": ingredient_counts
            })
        */
        return res.status(200).json({
            success: true,
            mealPlan: response.data
        });



    }
    catch(e) {
        console.error('Error generating meal plan:', e);
        
        // Handle different types of errors
        if (e.response) {
            // Python service returned an error
            return res.status(e.response.status).json({
                error: e.response.data.detail || 'Error from meal planning service'
            });
        } else if (e.request) {
            // Python service didn't respond
            return res.status(503).json({
                error: 'Meal planning service unavailable'
            });
        } else {
            // Other error
            return res.status(500).json({
                error: 'Failed to generate meal plan'
            });
        }
    }
}

module.exports = {
    createWeekPlan
};