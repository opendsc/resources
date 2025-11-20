// Copyright (c) Thomas Nieto - All Rights Reserved
// You may use, distribute and modify this code under the
// terms of the MIT license.

using System.Runtime.InteropServices;

namespace OpenDsc.Resource.Windows.Feature;

internal static class DismHelper
{
    public static (Schema schema, DismRestartType restartType) GetFeature(string featureName, bool? includeAllSubFeatures = null, string[]? source = null)
    {
        IntPtr session = IntPtr.Zero;
        IntPtr featureInfoPtr = IntPtr.Zero;

        try
        {
            DismApi.Initialize();
            session = DismApi.OpenOnlineSession();

            var hr = DismApi.DismGetFeatureInfo(
                session,
                featureName,
                null,
                DismPackageIdentifier.None,
                out featureInfoPtr);

            if (hr == unchecked((int)0x80070490) || hr == unchecked((int)0x800F080C)) // ERROR_NOT_FOUND or CBS_E_NOT_FOUND
            {
                return (new Schema
                {
                    Name = featureName,
                    Exist = false
                }, DismRestartType.No);
            }

            if (hr != 0)
            {
                var errorMessage = DismApi.GetLastErrorMessage();
                throw new InvalidOperationException(
                    $"Failed to get feature info for '{featureName}': 0x{hr:X8}" +
                    (errorMessage != null ? $" - {errorMessage}" : string.Empty));
            }

            // Manually read structure fields to avoid marshalling issues
            var offset = 0;
            var featureNamePtr = Marshal.ReadIntPtr(featureInfoPtr, offset);
            offset += IntPtr.Size;
            var state = (DismPackageFeatureState)Marshal.ReadInt32(featureInfoPtr, offset);
            offset += sizeof(int);
            var displayNamePtr = Marshal.ReadIntPtr(featureInfoPtr, offset);
            offset += IntPtr.Size;
            var descriptionPtr = Marshal.ReadIntPtr(featureInfoPtr, offset);
            offset += IntPtr.Size;
            var restartRequired = (DismRestartType)Marshal.ReadInt32(featureInfoPtr, offset);

            var isInstalled = state == DismPackageFeatureState.Installed ||
                            state == DismPackageFeatureState.InstallPending;

            return (new Schema
            {
                Name = featureNamePtr != IntPtr.Zero ? Marshal.PtrToStringUni(featureNamePtr) ?? string.Empty : string.Empty,
                Exist = isInstalled ? null : false,
                DisplayName = displayNamePtr != IntPtr.Zero ? Marshal.PtrToStringUni(displayNamePtr) : null,
                Description = descriptionPtr != IntPtr.Zero ? Marshal.PtrToStringUni(descriptionPtr) : null,
                State = state,
                IncludeAllSubFeatures = includeAllSubFeatures,
                Source = source
            }, restartRequired);
        }
        finally
        {
            if (featureInfoPtr != IntPtr.Zero)
            {
                DismApi.DismDelete(featureInfoPtr);
            }
            DismApi.CloseSession(session);
            DismApi.Shutdown();
        }
    }

    public static DismRestartType EnableFeature(string featureName, bool includeAllSubFeatures = false, string[]? sources = null)
    {
        IntPtr session = IntPtr.Zero;

        try
        {
            DismApi.Initialize();
            session = DismApi.OpenOnlineSession();

            var sourceCount = sources?.Length ?? 0;

            var hr = DismApi.DismEnableFeature(
                session,
                featureName,
                null,
                DismPackageIdentifier.None,
                limitAccess: false,
                sources,
                (uint)sourceCount,
                includeAllSubFeatures,
                IntPtr.Zero,
                IntPtr.Zero,
                IntPtr.Zero);

            if (hr != 0)
            {
                var errorMessage = DismApi.GetLastErrorMessage();
                throw new InvalidOperationException(
                    $"Failed to enable feature '{featureName}': 0x{hr:X8}" +
                    (errorMessage != null ? $" - {errorMessage}" : string.Empty));
            }

            // Get feature info to check restart requirement
            var (_, restartType) = GetFeature(featureName, includeAllSubFeatures, sources);
            return restartType;
        }
        finally
        {
            DismApi.CloseSession(session);
            DismApi.Shutdown();
        }
    }

    public static DismRestartType DisableFeature(string featureName, bool removePayload = false)
    {
        IntPtr session = IntPtr.Zero;

        try
        {
            DismApi.Initialize();
            session = DismApi.OpenOnlineSession();

            var hr = DismApi.DismDisableFeature(
                session,
                featureName,
                null,
                removePayload,
                IntPtr.Zero,
                IntPtr.Zero,
                IntPtr.Zero);

            if (hr != 0 && hr != unchecked((int)0x80070490)) // Ignore ERROR_NOT_FOUND
            {
                var errorMessage = DismApi.GetLastErrorMessage();
                throw new InvalidOperationException(
                    $"Failed to disable feature '{featureName}': 0x{hr:X8}" +
                    (errorMessage != null ? $" - {errorMessage}" : string.Empty));
            }

            // Get feature info to check restart requirement
            var (_, restartType) = GetFeature(featureName);
            return restartType;
        }
        finally
        {
            DismApi.CloseSession(session);
            DismApi.Shutdown();
        }
    }

    public static IEnumerable<Schema> EnumerateFeatures()
    {
        IntPtr session = IntPtr.Zero;
        IntPtr featuresPtr = IntPtr.Zero;

        try
        {
            DismApi.Initialize();
            session = DismApi.OpenOnlineSession();

            var hr = DismApi.DismGetFeatures(
                session,
                null,
                DismPackageIdentifier.None,
                out featuresPtr,
                out var count);

            if (hr != 0)
            {
                var errorMessage = DismApi.GetLastErrorMessage();
                throw new InvalidOperationException(
                    $"Failed to enumerate features: 0x{hr:X8}" +
                    (errorMessage != null ? $" - {errorMessage}" : string.Empty));
            }

            // DISM returns an array of DismFeature structures (not pointers)
            // Each structure: PCWSTR (8 bytes on x64) + DismPackageFeatureState (4 bytes int)
            // The struct has alignment, so actual size may be larger
            var structSize = Marshal.SizeOf<DismFeature>();

            for (var i = 0; i < count; i++)
            {
                // Calculate pointer to current structure in array
                var currentFeaturePtr = IntPtr.Add(featuresPtr, i * structSize);

                // Read fields directly with known offsets
                IntPtr featureNamePtr;
                DismPackageFeatureState state;

                try
                {
                    featureNamePtr = Marshal.ReadIntPtr(currentFeaturePtr, 0);
                    state = (DismPackageFeatureState)Marshal.ReadInt32(currentFeaturePtr, IntPtr.Size);
                }
                catch (AccessViolationException ex)
                {
                    // Log error and skip this feature
                    Console.Error.WriteLine($"Error reading feature at index {i}: {ex.Message}");
                    continue;
                }

                // Only export installed features
                if (state == DismPackageFeatureState.Installed ||
                    state == DismPackageFeatureState.InstallPending)
                {
                    var featureName = featureNamePtr != IntPtr.Zero
                        ? Marshal.PtrToStringUni(featureNamePtr)
                        : null;

                    if (featureName != null)
                    {
                        yield return new Schema
                        {
                            Name = featureName,
                            State = state
                        };
                    }
                }
            }
        }
        finally
        {
            if (featuresPtr != IntPtr.Zero)
            {
                DismApi.DismDelete(featuresPtr);
            }
            DismApi.CloseSession(session);
            DismApi.Shutdown();
        }
    }
}
