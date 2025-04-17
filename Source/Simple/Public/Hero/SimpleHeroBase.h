// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "Player/SimpleCharacterBase.h"
#include "SimpleHeroBase.generated.h"

class USimpleCameraComponent;
class USimpleInputComponent;
class USimpleHealthComponent;

UCLASS()
class SIMPLE_API ASimpleHeroBase : public ASimpleCharacterBase
{
	GENERATED_BODY()
public:
	ASimpleHeroBase(const FObjectInitializer& ObjectInitializer);

	virtual void PostInitializeComponents() override;

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

protected:
	virtual void OnInitializedAbilitySystem() override;

private:
	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Lyra|Character", Meta = (AllowPrivateAccess = "true"))
	TObjectPtr<USimpleCameraComponent> SimpleCameraComponent;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Lyra|Character", Meta = (AllowPrivateAccess = "true"))
	TObjectPtr<USimpleInputComponent> SimpleInputComponent;

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Lyra|Character", Meta = (AllowPrivateAccess = "true"))
	TObjectPtr<USimpleHealthComponent> SimpleHealthComponent;
};
