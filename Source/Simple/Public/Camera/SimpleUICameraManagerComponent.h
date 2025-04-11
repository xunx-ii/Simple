// Copyright Epic Games, Inc. All Rights Reserved.

#pragma once

#include "Camera/PlayerCameraManager.h"

#include "SimpleUICameraManagerComponent.generated.h"

class ASimplePlayerCameraManager;

class AActor;
class AHUD;
class APlayerController;
class FDebugDisplayInfo;
class UCanvas;
class UObject;

UCLASS( Transient, Within=SimplePlayerCameraManager )
class USimpleUICameraManagerComponent : public UActorComponent
{
	GENERATED_BODY()

public:
	static USimpleUICameraManagerComponent* GetComponent(APlayerController* PC);

public:
	USimpleUICameraManagerComponent();	
	virtual void InitializeComponent() override;

	bool IsSettingViewTarget() const { return bUpdatingViewTarget; }
	AActor* GetViewTarget() const { return ViewTarget; }
	void SetViewTarget(AActor* InViewTarget, FViewTargetTransitionParams TransitionParams = FViewTargetTransitionParams());

	bool NeedsToUpdateViewTarget() const;
	void UpdateViewTarget(struct FTViewTarget& OutVT, float DeltaTime);

	void OnShowDebugInfo(AHUD* HUD, UCanvas* Canvas, const FDebugDisplayInfo& DisplayInfo, float& YL, float& YPos);

private:
	UPROPERTY(Transient)
	TObjectPtr<AActor> ViewTarget;
	
	UPROPERTY(Transient)
	bool bUpdatingViewTarget;
};
