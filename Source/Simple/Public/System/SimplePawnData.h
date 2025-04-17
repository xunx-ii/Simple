// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Engine/DataAsset.h"
#include "SimplePawnData.generated.h"

class USimpleAbilitySet;
class USimpleInputConfig;
class USimpleCameraMode;

UCLASS()
class SIMPLE_API USimplePawnData : public UPrimaryDataAsset
{
	GENERATED_BODY()
public:

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Simple|Pawn")
	TSubclassOf<APawn> PawnClass;

	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = "Simple|Abilities")
	TArray<TObjectPtr<USimpleAbilitySet>> AbilitySets;
};
