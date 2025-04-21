// Fill out your copyright notice in the Description page of Project Settings.


#include "Online/SimpleGameMode.h"
#include "System/SimpleWorldSettings.h"
#include "System/SimpleAssetManager.h"
#include "Online/SimpleGameState.h"
#include "System/SimplePawnData.h"
#include "Player/SimplePlayerState.h"
#include "System/SimpleExperienceDefinition.h"
#include "Player/SimplePlayerController.h"
#include "Player/SimpleCharacterBase.h"


ASimpleGameMode::ASimpleGameMode()
{
	GameStateClass = ASimpleGameState::StaticClass();
	PlayerControllerClass = ASimplePlayerController::StaticClass();
	PlayerStateClass = ASimplePlayerState::StaticClass();
	DefaultPawnClass = ASimpleCharacterBase::StaticClass();
}

void ASimpleGameMode::InitGame(const FString& MapName, const FString& Options, FString& ErrorMessage)
{
	Super::InitGame(MapName, Options, ErrorMessage);

	GetWorld()->GetTimerManager().SetTimerForNextTick(this, &ThisClass::HandleMatchAssignmentIfNotExpectingOne);
}


void ASimpleGameMode::InitGameState()
{
	Super::InitGameState();

	ASimpleGameState* SimpleGameState = Cast<ASimpleGameState>(GameState);

	SimpleGameState->CallOrRegister_OnExperienceLoaded(FOnSimpleExperienceLoaded::FDelegate::CreateUObject(this, &ThisClass::OnExperienceLoaded));
}

void ASimpleGameMode::HandleStartingNewPlayer_Implementation(APlayerController* NewPlayer)
{
	ASimpleGameState* SimpleGameState = Cast<ASimpleGameState>(GameState);
	if (SimpleGameState->IsExperienceLoaded())
	{
		Super::HandleStartingNewPlayer_Implementation(NewPlayer);
	}
}

UClass* ASimpleGameMode::GetDefaultPawnClassForController_Implementation(AController* InController)
{
	if (const USimplePawnData* PawnData = GetPawnDataForController(InController))
	{
		if (PawnData->PawnClass)
		{
			return PawnData->PawnClass;
		}
	}

	return Super::GetDefaultPawnClassForController_Implementation(InController);
}

const USimplePawnData* ASimpleGameMode::GetPawnDataForController(const AController* InController) const
{
	if (InController != nullptr)
	{
		if (const ASimplePlayerState* SimplePlayerState = InController->GetPlayerState<ASimplePlayerState>())
		{
			if (const USimplePawnData* PawnData = SimplePlayerState->GetPawnData<USimplePawnData>())
			{
				return PawnData;
			}
		}
	}

	ASimpleGameState* SimpleGameState = Cast<ASimpleGameState>(GameState);

	if (SimpleGameState && SimpleGameState->IsExperienceLoaded())
	{
		const USimpleExperienceDefinition* Experience = SimpleGameState->GetCurrentExperience();

		if (Experience && Experience->DefaultPawnData != nullptr)
		{
			return Experience->DefaultPawnData;
		}

		return USimpleAssetManager::Get().GetDefaultPawnData();
	}

	return nullptr;
}


void ASimpleGameMode::OnExperienceLoaded(const USimpleExperienceDefinition* CurrentExperience)
{
	for (FConstPlayerControllerIterator Iterator = GetWorld()->GetPlayerControllerIterator(); Iterator; ++Iterator)
	{
		APlayerController* PC = Cast<APlayerController>(*Iterator);
		if ((PC != nullptr) && (PC->GetPawn() == nullptr))
		{
			if (PlayerCanRestart(PC))
			{
				RestartPlayer(PC);
			}
		}
	}
}

void ASimpleGameMode::HandleMatchAssignmentIfNotExpectingOne()
{
	FPrimaryAssetId ExperienceId;
	FString ExperienceIdSource;

	UWorld* World = GetWorld();

	// see if the world settings has a default experience
	if (!ExperienceId.IsValid())
	{
		if (ASimpleWorldSettings* TypedWorldSettings = Cast<ASimpleWorldSettings>(GetWorldSettings()))
		{
			ExperienceId = TypedWorldSettings->GetDefaultGameplayExperience();
			ExperienceIdSource = TEXT("WorldSettings");
		}
	}

	USimpleAssetManager& AssetManager = USimpleAssetManager::Get();

	FAssetData Dummy;
	if (ExperienceId.IsValid() && !AssetManager.GetPrimaryAssetData(ExperienceId, /*out*/ Dummy))
	{
		UE_LOG(LogClass, Error, TEXT("EXPERIENCE: Wanted to use %s but couldn't find it, falling back to the default)"), *ExperienceId.ToString());
		ExperienceId = FPrimaryAssetId();
	}

	OnMatchAssignmentGiven(ExperienceId, ExperienceIdSource);
}

void ASimpleGameMode::OnMatchAssignmentGiven(FPrimaryAssetId ExperienceId, const FString& ExperienceIdSource)
{
	if (ExperienceId.IsValid())
	{
		UE_LOG(LogClass, Log, TEXT("Identified experience %s (Source: %s)"), *ExperienceId.ToString(), *ExperienceIdSource);
		ASimpleGameState* SimpleGameState = Cast<ASimpleGameState>(GameState);
		if (SimpleGameState)
		{
			SimpleGameState->SetCurrentExperience(ExperienceId);
		}
	}
	else
	{
		UE_LOG(LogClass, Error, TEXT("Failed to identify experience, loading screen will stay up forever"));
	}
}
