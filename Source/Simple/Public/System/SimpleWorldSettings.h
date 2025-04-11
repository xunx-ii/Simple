// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/WorldSettings.h"
#include "SimpleWorldSettings.generated.h"

class USimpleExperienceDefinition;

UCLASS()
class SIMPLE_API ASimpleWorldSettings : public AWorldSettings
{
	GENERATED_BODY()
public:

	ASimpleWorldSettings(const FObjectInitializer& ObjectInitializer);

	FPrimaryAssetId GetDefaultGameplayExperience() const;

protected:
	UPROPERTY(EditDefaultsOnly, Category=GameMode)
	TSoftClassPtr<USimpleExperienceDefinition> DefaultGameplayExperience;
	
};
