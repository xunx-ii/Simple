// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "AbilitySystemInterface.h"
#include "GameFramework/PlayerState.h"
#include "SimplePlayerState.generated.h"

class USimplePawnData;
class USimpleExperienceDefinition;
class USimpleAbilitySystemComponent;

DECLARE_MULTICAST_DELEGATE_OneParam(FOnSimplePawnDataLoaded, const USimplePawnData* /*PawnData*/);

UCLASS()
class SIMPLE_API ASimplePlayerState : public APlayerState, public IAbilitySystemInterface
{
	GENERATED_BODY()
public:
	ASimplePlayerState();

	virtual void PostInitializeComponents() override;
	
	template <class T>
	const T* GetPawnData() const { return Cast<T>(GamePawnData); }

	void SetPawnData(const USimplePawnData* PawnData);

	UFUNCTION(BlueprintCallable, Category = "Simple|PlayerState")
	USimpleAbilitySystemComponent* GetSimpleAbilitySystemComponent() const { return AbilitySystemComponent; }
	virtual UAbilitySystemComponent* GetAbilitySystemComponent() const override;

	void CallOrRegister_OnPawnDataLoaded(FOnSimplePawnDataLoaded::FDelegate&& Delegate);
private:
	void OnExperienceLoaded(const USimpleExperienceDefinition* CurrentExperience);
	
protected:
	UFUNCTION()
	void OnRep_GamePawnData();

protected:

	UPROPERTY(ReplicatedUsing = OnRep_GamePawnData)
	TObjectPtr<const USimplePawnData> GamePawnData;

	FOnSimplePawnDataLoaded OnPawnDataLoaded;
private:
	bool bPawnDataIsLoaded;
	
	UPROPERTY(VisibleAnywhere, Category = "Lyra|PlayerState")
	TObjectPtr<USimpleAbilitySystemComponent> AbilitySystemComponent;
};
