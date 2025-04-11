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
class USimpleCameraComponent;
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

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

	TSubclassOf<USimpleCameraMode> DetermineCameraMode() const;

	UPROPERTY(Transient)
	TObjectPtr<USimpleAbilitySystemComponent> AbilitySystemComponent;

	void UninitializeAbilitySystem();
	void InitializePlayerInput(class UInputComponent* PlayerInputComponent);
	void InitializeAbilitySystem(USimpleAbilitySystemComponent* InSimpleAbilitySystemComponent, AActor* InOwnerActor);

	void Input_Move(const FInputActionValue& InputActionValue);
	void Input_LookMouse(const FInputActionValue& InputActionValue);

	void Input_AbilityInputTagPressed(FGameplayTag InputTag);
	void Input_AbilityInputTagReleased(FGameplayTag InputTag);

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

private:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Lyra|Character", Meta = (AllowPrivateAccess = "true"))
	TObjectPtr<USimpleCameraComponent> SimpleCameraComponent;

	UPROPERTY()
	const USimplePawnData* PawnData;
};
