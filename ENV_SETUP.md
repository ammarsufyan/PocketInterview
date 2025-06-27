# Environment Variables Setup Guide

## 📋 Overview

This guide explains how to set up environment variables for the InterviewSim app, including Tavus API integration and Supabase configuration.

## 🔧 Setup Steps

### 1. Create .env File

Create a `.env` file in your project root directory:

```bash
# Tavus API Configuration
TAVUS_API_KEY=your_actual_tavus_api_key_here
TAVUS_BASE_URL=https://tavusapi.com/v2

# Supabase Configuration
SUPABASE_URL=your_supabase_project_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

### 2. Get Tavus Credentials

#### API Key:
1. Go to [Tavus Platform](https://platform.tavus.io/api-keys)
2. Sign up or log in to your account
3. Create a new API key
4. Copy the API key and replace `your_actual_tavus_api_key_here` in your `.env` file

**Note**: No replica setup needed! The app will use Tavus's direct conversation API without requiring a pre-configured replica.

### 3. Get Supabase Credentials

#### Project URL and API Key:
1. Go to your [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project (or create a new one)
3. Go to Settings → API
4. Copy the following values to your `.env` file:
   - **Project URL** → `SUPABASE_URL`
   - **anon public key** → `SUPABASE_ANON_KEY`

Example:
```bash
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

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
<key>TAVUS_BASE_URL</key>
<string>$(TAVUS_BASE_URL)</string>
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
- Never commit actual credentials to version control

### ❌ Don't:
- Commit `.env` file to version control
- Share API keys in plain text
- Use production keys in development
- Hardcode sensitive values in source code

## 🧪 Testing Configuration

Test your configuration by running:

```swift
// In your app or tests
let isTavusValid = EnvironmentConfig.shared.validateTavusConfiguration()
print("Tavus config valid: \(isTavusValid)")

let isSupabaseValid = EnvironmentConfig.shared.validateSupabaseConfiguration()
print("Supabase config valid: \(isSupabaseValid)")

// Test Supabase connection
let isSupabaseConnected = SupabaseConfig.validateConfiguration()
print("Supabase connection valid: \(isSupabaseConnected)")
```

## 🐛 Troubleshooting

### Common Issues:

1. **"SUPABASE_URL not found"**
   - Check if `.env` file exists in project root
   - Verify the file is added to Xcode target
   - Check for typos in environment variable names
   - Ensure the URL format is correct (https://your-project.supabase.co)

2. **"SUPABASE_ANON_KEY not found"**
   - Verify you copied the correct anon key from Supabase dashboard
   - Check for extra spaces or line breaks
   - Ensure the key starts with "eyJ"

3. **"TAVUS_API_KEY not found"**
   - Verify the API key is correct in Tavus dashboard
   - Check for extra spaces or characters
   - Ensure the key has proper permissions

4. **"Conversation creation failed"**
   - Check your Tavus API quota and limits
   - Verify the API endpoint is correct
   - Check network connectivity

### Debug Commands:

```swift
// Print all loaded environment variables (masked)
EnvironmentConfig.shared.printLoadedVariables()

// Check specific values
print("Tavus API Key exists: \(EnvironmentConfig.shared.tavusApiKey != nil)")
print("Supabase URL exists: \(EnvironmentConfig.shared.supabaseURL != nil)")
print("Supabase Key exists: \(EnvironmentConfig.shared.supabaseAnonKey != nil)")

// Print Supabase configuration
SupabaseConfig.shared.printConfiguration()
```

## 📁 File Structure

```
InterviewSim/
├── .env                          # Environment variables (not in git)
├── .gitignore                    # Includes .env
├── Config/
│   ├── EnvironmentConfig.swift   # Environment loader
│   ├── TavusConfig.swift         # Tavus configuration
│   └── SupabaseConfig.swift      # Supabase configuration (updated)
└── Services/
    ├── TavusService.swift        # Tavus API service
    ├── AuthenticationManager.swift # Supabase auth
    └── InterviewHistoryManager.swift # Supabase data
```

## 🚀 Benefits of Environment Configuration

### ✅ **Security**
- No hardcoded credentials in source code
- Easy to rotate keys without code changes
- Different keys for different environments

### ✅ **Flexibility**
- Easy to switch between development and production
- Team members can use their own credentials
- CI/CD friendly configuration

### ✅ **Maintainability**
- Centralized configuration management
- Clear separation of code and configuration
- Easy to debug configuration issues

## 🔄 Migration from Hardcoded Values

If you're migrating from hardcoded values:

1. **Backup your current credentials** from the hardcoded files
2. **Add them to `.env` file** using the format above
3. **Test the configuration** using the debug commands
4. **Remove hardcoded values** from source files
5. **Verify everything works** before committing

## 📞 Support

If you encounter issues:
- Check the Tavus [API Documentation](https://docs.tavus.io)
- Review Supabase [Setup Guide](https://supabase.com/docs)
- Verify your API quotas and limits
- Check the [Supabase Database Setup](SUPABASE_SETUP.md) guide
- Contact support if needed

---

**Remember**: Never commit your actual API keys to version control! 🔐

## 📝 Example .env Template

```bash
# Copy this template and replace with your actual values

# Tavus API Configuration
TAVUS_API_KEY=your_actual_tavus_api_key_here
TAVUS_BASE_URL=https://tavusapi.com/v2

# Supabase Configuration  
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Optional: Additional configuration
# DEBUG_MODE=true
# LOG_LEVEL=verbose
```