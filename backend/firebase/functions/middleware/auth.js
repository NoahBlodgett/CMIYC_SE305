const { getAuth } = require('firebase-admin/auth');

async function authenticate(req, res, next) 
{
  try {
    // Extract token from Authorization header
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ 
        error: 'No authentication token provided' 
      });
    }

    const token = authHeader.split('Bearer ')[1];

    // Verify the token with Firebase Auth
    const auth = getAuth();
    const decodedToken = await auth.verifyIdToken(token);

    // Attach user info to request for use in controllers
    req.user = {
      uid: decodedToken.uid,
      email: decodedToken.email,
      emailVerified: decodedToken.email_verified
    };

    next(); // Continue to the controller
  } catch (error) {
    console.error('Authentication error:', error);

    // Handle specific token errors
    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({ 
        error: 'Token has expired' 
      });
    }
    if (error.code === 'auth/id-token-revoked') {
      return res.status(401).json({ 
        error: 'Token has been revoked' 
      });
    }
    if (error.code === 'auth/argument-error') {
      return res.status(401).json({ 
        error: 'Invalid token format' 
      });
    }

    res.status(401).json({ 
      error: 'Invalid authentication token' 
    });
  }
}


function authorizeUser(req, res, next) 
{
  const { userID } = req.params;
  
  if (!req.user) {
    return res.status(401).json({ 
      error: 'Authentication required' 
    });
  }

  if (req.user.uid !== userID) {
    return res.status(403).json({ 
      error: 'Unauthorized: You can only access your own account' 
    });
  }

  next();
}

/**
 * Optional: Middleware to check if email is verified
 * Can be used for operations that require verified emails
 */
function requireEmailVerification(req, res, next) 
{
  if (!req.user) {
    return res.status(401).json({ 
      error: 'Authentication required' 
    });
  }

  if (!req.user.emailVerified) {
    return res.status(403).json({ 
      error: 'Email verification required for this operation' 
    });
  }

  next();
}

const rateLimitStore = new Map();

function rateLimit(maxRequests = 10, windowMs = 60000) 
{
  return (req, res, next) => {
    const identifier = req.user?.uid || req.ip;
    const now = Date.now();
    
    if (!rateLimitStore.has(identifier)) {
      rateLimitStore.set(identifier, []);
    }

    const requests = rateLimitStore.get(identifier);
    
    // Remove old requests outside the time window
    const validRequests = requests.filter(timestamp => now - timestamp < windowMs);
    
    if (validRequests.length >= maxRequests) {
      return res.status(429).json({ 
        error: 'Too many requests. Please try again later.' 
      });
    }

    validRequests.push(now);
    rateLimitStore.set(identifier, validRequests);
    
    next();
  };
}

module.exports = {
  authenticate,
  authorizeUser,
  requireEmailVerification,
  rateLimit
};
