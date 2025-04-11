// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/GameModeBase.h"
#include "SimpleGameMode.generated.h"

class USimplePawnData;
class USimpleExperienceDefinition;

UCLASS()
class SIMPLE_API ASimpleGameMode : public AGameModeBase
{
	GENERATED_BODY()
public:
	ASimpleGameMode();

	virtual void InitGame(const FString& MapName, const FString& Options, FString& ErrorMessage) override;
	virtual UClass* GetDefaultPawnClassForController_Implementation(AController* InController) override;
	virtual void HandleStartingNewPlayer_Implementation(APlayerController* NewPlayer) override;
	virtual void InitGameState() override;

	UFUNCTION(BlueprintCallable, Category = "Simple|Pawn")
	const USimplePawnData* GetPawnDataForController(const AController* InController) const;
protected:
	void OnExperienceLoaded(const USimpleExperienceDefinition* CurrentExperience);
	void HandleMatchAssignmentIfNotExpectingOne();
	void OnMatchAssignmentGiven(FPrimaryAssetId ExperienceId, const FString& ExperienceIdSource);
};
