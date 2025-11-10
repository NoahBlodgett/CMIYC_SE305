const { Weight_Objectives } = require('../models/WeightGoals');
const { ActiveGoals } = require('../models/ActivityGoals');


function isValidWeightObjective(objective) 
{
  if (!Weight_Objectives || typeof Weight_Objectives !== 'object') return false;
  return Object.values(Weight_Objectives).includes(objective);
}

function isValidActiveGoal(goal) 
{
  if (!ActiveGoals || typeof ActiveGoals !== 'object') return false;
  return Object.values(ActiveGoals).includes(goal);
}


function isValidGoalWeight(weight) 
{
  return typeof weight === 'number' && Number.isFinite(weight) && weight > 0 && weight < 1000;
}

function isValidFinishDate(date) 
{
  if (!date) return false;
  const finishDate = date instanceof Date ? date : new Date(date);
  const time = finishDate.getTime();
  if (!Number.isFinite(time)) return false; // invalid date
  return time > Date.now();
}

function isValidGoalID(goalID) 
{
  return typeof goalID === 'string' && goalID.trim().length > 0;
}

module.exports = {
  isValidWeightObjective,
  isValidActiveGoal,
  isValidGoalWeight,
  isValidFinishDate,
  isValidGoalID,
};