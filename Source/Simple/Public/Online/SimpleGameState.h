// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameStateBase.h"
#include "SimpleGameState.generated.h"

class USimpleExperienceDefinition;

DECLARE_MULTICAST_DELEGATE_OneParam(FOnSimpleExperienceLoaded, const USimpleExperienceDefinition* /*Experience*/);

UCLASS()
class SIMPLE_API ASimpleGameState : public AGameStateBase
{
	GENERATED_BODY()
public:
	ASimpleGameState();

	bool IsExperienceLoaded() const;

	void SetCurrentExperience(FPrimaryAssetId ExperienceId);

	const USimpleExperienceDefinition* GetCurrentExperience() const;

	void CallOrRegister_OnExperienceLoaded(FOnSimpleExperienceLoaded::FDelegate&& Delegate);
private:
	UFUNCTION()
	void OnRep_CurrentExperience();

	void StartExperienceLoad();

	void LoadingAssetsInTheExperience(const USimpleExperienceDefinition* Experience);

	void OnExperienceLoadComplete();
private:
	UPROPERTY(ReplicatedUsing=OnRep_CurrentExperience)
	TObjectPtr<const USimpleExperienceDefinition> CurrentExperience;

	FOnSimpleExperienceLoaded OnExperienceLoaded;

	bool bIsExperienceLoaded;
};
