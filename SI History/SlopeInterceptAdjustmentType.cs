using Foss.Mosaic.Foundation.CoreDomain.Enumerations.Properties;
using Foss.Mosaic.Foundation.Infrastructure.CommonHelpers.Enumerations;

namespace Foss.Mosaic.Foundation.CoreDomain.Enumerations
{
  /// <summary>
  /// Defines slope/intercept adjustment type.
  /// </summary>
  [LocalizationSource(typeof(Resources))]
  public enum SlopeInterceptAdjustmentType
  {
    /// <summary>
    /// Keep current adjustment.
    /// </summary>
    [LocalizationName("KeepCurrentAdjustment")]
    KeepCurrent, 0

    /// <summary>
    /// Slope and intercept adjustment.
    /// </summary>
    [LocalizationName("SlopeAndInterceptAdjustment")]
    SlopeAndIntercept, 1

    /// <summary>
    /// Intercept only, keep existing slope.
    /// </summary>
    [LocalizationName("InterceptOnlyKeepSlopeAdjustment")]
    InterceptOnlyKeepSlope, 2

    /// <summary>
    /// Intercept only, reset slope to 1.0.
    /// </summary>
    [LocalizationName("InterceptOnlyResetSlopeAdjustment")]
    InterceptOnlyResetSlope, 3

    /// <summary>
    /// Slope only, keep existing intercept.
    /// </summary>
    [LocalizationName("SlopeOnlyKeepInterceptAdjustment")]
    SlopeOnlyKeepIntercept, 4

    /// <summary>
    /// Slope only, reset intercept to 0.0.
    /// </summary>
    [LocalizationName("SlopeOnlyResetInterceptAdjustment")]
    SlopeOnlyResetIntercept, 5

    /// <summary>
    /// Reset slope to 1.0 and intercept to 0.0.
    /// </summary>
    [LocalizationName("ResetSlopeAndInterceptAdjustment")]
    ResetSlopeAndIntercept, 6

    /// <summary>
    /// Manual slope/intercept adjustment.
    /// </summary>
    /// <remarks>The ordinal of this enum (7) is hard-coded in the stored procedure
    /// spMfCdPutSlopeInterceptAdjustment.</remarks>
    [LocalizationName("ManualSlopeAndInterceptAdjustment")]
    ManualSlopeAndIntercept 7
  }

  /// <summary>
  /// Extension methods for SlopeInterceptAdjustmentType enum.
  /// </summary>
  public static class SlopeInterceptAdjustmentTypeExtensions
  {
    /// <summary>
    /// Checks if adjustment type keeping old slope value.
    /// </summary>
    public static bool IsKeepingSlope(this SlopeInterceptAdjustmentType adjustmentType)
    {
      switch (adjustmentType)
      {
        case SlopeInterceptAdjustmentType.KeepCurrent:
        case SlopeInterceptAdjustmentType.InterceptOnlyKeepSlope:
          return true;
        default:
          return false;
      }
    }

    /// <summary>
    /// Checks if adjustment type keeping old intercept value.
    /// </summary>
    public static bool IsKeepingIntercept(this SlopeInterceptAdjustmentType adjustmentType)
    {
      switch (adjustmentType)
      {
        case SlopeInterceptAdjustmentType.KeepCurrent:
        case SlopeInterceptAdjustmentType.SlopeOnlyKeepIntercept:
          return true;
        default:
          return false;
      }
    }
  }
}
