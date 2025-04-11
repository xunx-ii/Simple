// Copyright Epic Games, Inc. All Rights Reserved.

#include "Camera/SimpleUICameraManagerComponent.h"

#include "GameFramework/HUD.h"
#include "GameFramework/PlayerController.h"
#include "Camera/SimplePlayerCameraManager.h"

#include UE_INLINE_GENERATED_CPP_BY_NAME(SimpleUICameraManagerComponent)

class AActor;
class FDebugDisplayInfo;

USimpleUICameraManagerComponent* USimpleUICameraManagerComponent::GetComponent(APlayerController* PC)
{
	if (PC != nullptr)
	{
		if (ASimplePlayerCameraManager* PCCamera = Cast<ASimplePlayerCameraManager>(PC->PlayerCameraManager))
		{
			return PCCamera->GetUICameraComponent();
		}
	}

	return nullptr;
}

USimpleUICameraManagerComponent::USimpleUICameraManagerComponent()
{
	bWantsInitializeComponent = true;

	if (!HasAnyFlags(RF_ClassDefaultObject))
	{
		// Register "showdebug" hook.
		if (!IsRunningDedicatedServer())
		{
			AHUD::OnShowDebugInfo.AddUObject(this, &ThisClass::OnShowDebugInfo);
		}
	}
}

void USimpleUICameraManagerComponent::InitializeComponent()
{
	Super::InitializeComponent();
}

void USimpleUICameraManagerComponent::SetViewTarget(AActor* InViewTarget, FViewTargetTransitionParams TransitionParams)
{
	TGuardValue<bool> UpdatingViewTargetGuard(bUpdatingViewTarget, true);

	ViewTarget = InViewTarget;
	CastChecked<ASimplePlayerCameraManager>(GetOwner())->SetViewTarget(ViewTarget, TransitionParams);
}

bool USimpleUICameraManagerComponent::NeedsToUpdateViewTarget() const
{
	return false;
}

void USimpleUICameraManagerComponent::UpdateViewTarget(struct FTViewTarget& OutVT, float DeltaTime)
{
}

void USimpleUICameraManagerComponent::OnShowDebugInfo(AHUD* HUD, UCanvas* Canvas, const FDebugDisplayInfo& DisplayInfo, float& YL, float& YPos)
{
}
