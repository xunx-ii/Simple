// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "AbilitySystemInterface.h"
#include "GameFramework/Character.h"
#include "SimpleCharacterBase.generated.h"

struct FGameplayTag;
struct FInputActionValue;

class USimplePawnData;
class USimpleCameraMode;
class USimpleAbilitySystemComponent;

UCLASS()
class ASimpleCharacterBase : public ACharacter, public IAbilitySystemInterface
{
	GENERATED_BODY()

public:
	// Sets default values for this character's properties
	ASimpleCharacterBase(const FObjectInitializer& ObjectInitializer = FObjectInitializer::Get());

	UFUNCTION(BlueprintCallable, Category = "Simple|Character")
	USimpleAbilitySystemComponent* GetSimpleAbilitySystemComponent() const { return AbilitySystemComponent; }
	virtual UAbilitySystemComponent* GetAbilitySystemComponent() const override;

	// Server only
	virtual void PossessedBy(AController* NewController) override;
	// Client only
	virtual void OnRep_PlayerState() override;

	UFUNCTION(BlueprintImplementableEvent, Category = "Simple")
	void K2_OnInitializedAbilitySystem(USimpleAbilitySystemComponent* SimpleAbilitySystemComponent);

protected:

	void UninitializeAbilitySystem();

	void InitializeAbilitySystem(USimpleAbilitySystemComponent* InSimpleAbilitySystemComponent, AActor* InOwnerActor);

	virtual void OnInitializedAbilitySystem();

	UFUNCTION()
	virtual void OnDeathStarted(AActor* OwningActor);

	UFUNCTION()
	virtual void OnDeathFinished(AActor* OwningActor);

	UFUNCTION(BlueprintImplementableEvent, meta=(DisplayName="OnDeathFinished"))
	void K2_OnDeathFinished();

	void DisableMovementAndCollision();
	void DestroyDueToDeath();
	void UninitAndDestroy();

protected:

	UPROPERTY(Transient)
	TObjectPtr<USimpleAbilitySystemComponent> AbilitySystemComponent;
};
