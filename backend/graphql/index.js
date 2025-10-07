const { ApolloServer } = require('@apollo/server');
const typeDefs = require('./schema');
const { resolvers, resolveUser } = require('./resolvers');

// Create Apollo Server instance
function createApolloServer() {
  return new ApolloServer({
    typeDefs,
    resolvers,
    formatError: (formattedError, error) => {
      // Log errors for debugging
      console.error('GraphQL Error:', formattedError);
      return formattedError;
    },
    introspection: true, // Enable GraphQL Playground in development
  });
}

// Context function to extract user from request
async function getContext(req) {
  const token = req.headers.authorization?.replace('Bearer ', '') || 
                req.headers['x-session-token'];
  
  const user = token ? await resolveUser(token) : null;
  
  return { user };
}

// Create Express middleware for Apollo Server
function createGraphQLHandler(apolloServer) {
  return async (req, res) => {
    try {
      const context = await getContext(req);
      
      // Parse GraphQL request
      const { query, variables, operationName } = req.body;
      
      // Execute GraphQL operation
      const result = await apolloServer.executeOperation(
        {
          query,
          variables,
          operationName,
        },
        { contextValue: context }
      );
      
      // Send response
      res.status(200).json(result.body.singleResult || result.body);
    } catch (error) {
      console.error('GraphQL handler error:', error);
      res.status(500).json({ 
        errors: [{ message: 'Internal server error', error: error.message }] 
      });
    }
  };
}

module.exports = { createApolloServer, getContext, createGraphQLHandler };
