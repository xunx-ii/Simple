// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "SimpleExperienceDefinition.generated.h"

class USimplePawnData;

UCLASS(BlueprintType, Const)
class SIMPLE_API USimpleExperienceDefinition : public UPrimaryDataAsset
{
	GENERATED_BODY()

public:
	USimpleExperienceDefinition();

	UPROPERTY(EditDefaultsOnly, Category=Gameplay)
	TObjectPtr<const USimplePawnData> DefaultPawnData;
	
};
