const typeDefs = `
  type Query {
    supportRequests(status: String, userId: String): [SupportRequest!]!
    supportRequest(id: ID!): SupportRequest
  }

  type Mutation {
    createSupportRequest(input: CreateSupportRequestInput!): CreateSupportRequestPayload!
    updateSupportRequest(id: ID!, input: UpdateSupportRequestInput!): UpdateSupportRequestPayload!
  }

  type SupportRequest {
    id: ID!
    subject: String!
    message: String!
    category: String!
    priority: String!
    status: String!
    userId: String
    notes: [Note!]!
    meta: JSON
    createdAt: String!
    updatedAt: String!
  }

  type Note {
    body: String!
    author: String!
    createdAt: String!
  }

  input CreateSupportRequestInput {
    subject: String!
    message: String!
    category: String
    priority: String
    meta: JSON
  }

  input UpdateSupportRequestInput {
    status: String
    note: String
  }

  type CreateSupportRequestPayload {
    success: Boolean!
    id: String
    message: String
  }

  type UpdateSupportRequestPayload {
    success: Boolean!
    updated: Boolean
    message: String
  }

  scalar JSON
`;

module.exports = typeDefs;
