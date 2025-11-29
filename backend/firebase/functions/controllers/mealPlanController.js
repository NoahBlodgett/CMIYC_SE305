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

        // Find weight goal by userID
        const goalQuery = await db.collection('weight_goals')
            .where('user_id', '==', userID)
            .limit(1)
            .get();

        if (goalQuery.empty)
        {
            return res.status(404).json({
                error: 'Weight goal does not exist for this user'
            });
        }

        // Get the goal data
        const goalDoc = goalQuery.docs[0];
        let goalData = goalDoc.data();

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
        const transformedUserData = {
            Height_in: userData.height,
            Weight_lb: userData.weight,
            Age: userData.age,
            Gender: userData.gender === "male" ? 1 : 0,  // Convert string to number
            Activity_Level: userData.activity_level,
            Goal: goal,
            allergies: userData.allergies || [],  // Default empty array if missing
            preferences: userData.preferences || []  // Default empty array if missing
        };

        const response = await axios.post(`${ML_SERVICE_URL}/nutrition/generate`, transformedUserData);

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