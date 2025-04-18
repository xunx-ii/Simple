// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/PlayerController.h"
#include "SimplePlayerController.generated.h"

/**
 * 
 */
UCLASS()
class SIMPLE_API ASimplePlayerController : public APlayerController
{
	GENERATED_BODY()
	
public:
	ASimplePlayerController();

	virtual void ReceivedPlayer() override;
	virtual void PostProcessInput(const float DeltaTime, const bool bGamePaused) override;
	
};
