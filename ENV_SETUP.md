# Environment Variables Setup Guide

## 📋 Overview

This guide explains how to set up environment variables for the InterviewSim app, including Tavus API integration and Supabase configuration.

## 🔧 Setup Steps

### 1. Create .env File

Create a `.env` file in your project root directory:

```bash
# Tavus API Configuration
TAVUS_API_KEY=your_actual_tavus_api_key_here
TAVUS_REPLICA_ID=your_actual_replica_id_here
TAVUS_BASE_URL=https://tavusapi.com/v2

# Supabase Configuration
SUPABASE_URL=https://icwmrtklyfnwrbpqhksm.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imljd21ydGtseWZud3JicHFoa3NtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA4NTU5NjYsImV4cCI6MjA2NjQzMTk2Nn0.howPW3vqhNEWpX3o8eaYBhoaHDuvDM93WOSuzkcrPzI
```

### 2. Get Tavus Credentials

#### API Key:
1. Go to [Tavus Platform](https://platform.tavus.io/api-keys)
2. Sign up or log in to your account
3. Create a new API key
4. Copy the API key and replace `your_actual_tavus_api_key_here` in your `.env` file

#### Replica ID:
1. Go to [Tavus Replicas](https://platform.tavus.io/replicas)
2. Create a new replica (AI interviewer persona)
3. Customize the replica's appearance and voice
4. Copy the Replica ID and replace `your_actual_replica_id_here` in your `.env` file

### 3. Verify Supabase Configuration

The Supabase credentials are already configured, but you can verify them:

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project
3. Go to Settings → API
4. Verify the URL and anon key match your `.env` file

### 4. Add .env to Xcode (Development)

For development builds, you need to add the `.env` file to your Xcode project:

1. Drag the `.env` file into your Xcode project
2. Make sure "Add to target" is checked for your app target
3. The `EnvironmentConfig.swift` will automatically load these variables

### 5. Production Configuration

For production builds, add environment variables to your Info.plist:

```xml
<key>TAVUS_API_KEY</key>
<string>$(TAVUS_API_KEY)</string>
<key>TAVUS_REPLICA_ID</key>
<string>$(TAVUS_REPLICA_ID)</string>
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>
<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
```

Then configure these in your Xcode build settings or CI/CD pipeline.

## 🔒 Security Best Practices

### ✅ Do:
- Keep `.env` file in `.gitignore`
- Use different API keys for development and production
- Rotate API keys regularly
- Use Xcode build configurations for different environments

### ❌ Don't:
- Commit `.env` file to version control
- Share API keys in plain text
- Use production keys in development
- Hardcode sensitive values in source code

## 🧪 Testing Configuration

Test your configuration by running:

```swift
// In your app or tests
let isValid = EnvironmentConfig.shared.validateTavusConfiguration()
print("Tavus config valid: \(isValid)")

let supabaseValid = EnvironmentConfig.shared.validateSupabaseConfiguration()
print("Supabase config valid: \(supabaseValid)")
```

## 🐛 Troubleshooting

### Common Issues:

1. **"API key not found"**
   - Check if `.env` file exists in project root
   - Verify the file is added to Xcode target
   - Check for typos in environment variable names

2. **"Invalid API key"**
   - Verify the API key is correct in Tavus dashboard
   - Check for extra spaces or characters
   - Ensure the key has proper permissions

3. **"Replica not found"**
   - Verify the Replica ID in Tavus dashboard
   - Check if the replica is active and published
   - Ensure the replica supports conversations

### Debug Commands:

```swift
// Print all loaded environment variables (masked)
EnvironmentConfig.shared.printLoadedVariables()

// Check specific values
print("Tavus API Key exists: \(EnvironmentConfig.shared.tavusApiKey != nil)")
print("Replica ID exists: \(EnvironmentConfig.shared.tavusReplicaId != nil)")
```

## 📁 File Structure

```
InterviewSim/
├── .env                          # Environment variables (not in git)
├── .gitignore                    # Includes .env
├── Config/
│   ├── EnvironmentConfig.swift   # Environment loader
│   ├── TavusConfig.swift         # Tavus configuration
│   └── SupabaseConfig.swift      # Supabase configuration
└── Services/
    └── TavusService.swift        # Tavus API service
```

## 🚀 Next Steps

After setting up environment variables:

1. Test the Tavus integration with a sample conversation
2. Verify Supabase connection and data operations
3. Test the full interview flow from CV upload to AI conversation
4. Configure production environment variables for deployment

## 📞 Support

If you encounter issues:
- Check the Tavus [API Documentation](https://docs.tavus.io)
- Review Supabase [Setup Guide](https://supabase.com/docs)
- Verify your API quotas and limits
- Contact support if needed

---

**Remember**: Never commit your actual API keys to version control! 🔐