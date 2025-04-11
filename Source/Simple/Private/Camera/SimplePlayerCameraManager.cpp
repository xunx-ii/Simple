// Copyright Epic Games, Inc. All Rights Reserved.

#include "Camera/SimplePlayerCameraManager.h"

#include "Async/TaskGraphInterfaces.h"
#include "Engine/Canvas.h"
#include "Engine/Engine.h"
#include "GameFramework/Pawn.h"
#include "GameFramework/PlayerController.h"
#include "Camera/SimpleCameraComponent.h"
#include "Camera/SimpleUICameraManagerComponent.h"

#include UE_INLINE_GENERATED_CPP_BY_NAME(SimplePlayerCameraManager)

class FDebugDisplayInfo;

static FName UICameraComponentName(TEXT("UICamera"));

ASimplePlayerCameraManager::ASimplePlayerCameraManager(const FObjectInitializer& ObjectInitializer)
	: Super(ObjectInitializer)
{
	DefaultFOV = LYRA_CAMERA_DEFAULT_FOV;
	ViewPitchMin = LYRA_CAMERA_DEFAULT_PITCH_MIN;
	ViewPitchMax = LYRA_CAMERA_DEFAULT_PITCH_MAX;

	UICamera = CreateDefaultSubobject<USimpleUICameraManagerComponent>(UICameraComponentName);
}

USimpleUICameraManagerComponent* ASimplePlayerCameraManager::GetUICameraComponent() const
{
	return UICamera;
}

void ASimplePlayerCameraManager::UpdateViewTarget(FTViewTarget& OutVT, float DeltaTime)
{
	// If the UI Camera is looking at something, let it have priority.
	if (UICamera->NeedsToUpdateViewTarget())
	{
		Super::UpdateViewTarget(OutVT, DeltaTime);
		UICamera->UpdateViewTarget(OutVT, DeltaTime);
		return;
	}

	Super::UpdateViewTarget(OutVT, DeltaTime);
}

void ASimplePlayerCameraManager::DisplayDebug(UCanvas* Canvas, const FDebugDisplayInfo& DebugDisplay, float& YL, float& YPos)
{
	check(Canvas);

	FDisplayDebugManager& DisplayDebugManager = Canvas->DisplayDebugManager;

	DisplayDebugManager.SetFont(GEngine->GetSmallFont());
	DisplayDebugManager.SetDrawColor(FColor::Yellow);
	DisplayDebugManager.DrawString(FString::Printf(TEXT("SimplePlayerCameraManager: %s"), *GetNameSafe(this)));

	Super::DisplayDebug(Canvas, DebugDisplay, YL, YPos);

	const APawn* Pawn = (PCOwner ? PCOwner->GetPawn() : nullptr);

	if (const USimpleCameraComponent* CameraComponent = USimpleCameraComponent::FindCameraComponent(Pawn))
	{
		CameraComponent->DrawDebug(Canvas);
	}
}

